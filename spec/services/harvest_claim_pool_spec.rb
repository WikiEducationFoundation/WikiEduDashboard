# frozen_string_literal: true

require 'rails_helper'

describe HarvestClaimPool do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:article) { create(:article, namespace: Article::Namespaces::MAINSPACE, wiki:) }
  let(:alert) do
    create(:ai_edit_alert, article:, revision_id: 100,
                           details: { article_title: 'Dynamical_decoupling' })
  end

  # Stub the per-alert harvester so the spec makes no external API calls.
  def stub_harvester(claim_count)
    claims = Array.new(claim_count) { instance_double(VerificationClaim) }
    allow(HarvestAiEditAlertClaims).to receive(:new)
      .and_return(instance_double(HarvestAiEditAlertClaims, claims:))
  end

  def seed_pool_entry
    VerificationClaim.create!(wiki:, mw_rev_id: alert.revision_id, sentence: 'seed')
  end

  it 'harvests mainspace alerts and records a run summary in Setting' do
    alert
    stub_harvester(3)
    harvest = described_class.new
    expect(harvest.processed).to eq(1)
    expect(harvest.harvested).to eq(3)
    expect(HarvestAiEditAlertClaims).to have_received(:new).with(alert)
    summary = Setting.find_by(key: 'claim_harvest').value['last_summary']
    expect(summary).to include('processed' => 1, 'harvested' => 3, 'skipped' => 0)
  end

  it 'skips revisions already represented in the pool (set-based dedup)' do
    alert
    seed_pool_entry
    stub_harvester(3)
    harvest = described_class.new
    expect(harvest.processed).to eq(0)
    expect(HarvestAiEditAlertClaims).not_to have_received(:new)
  end

  it 'reprocesses pooled revisions when full_rescan is set' do
    alert
    seed_pool_entry
    stub_harvester(2)
    harvest = described_class.new(full_rescan: true)
    expect(harvest.processed).to eq(1)
    expect(HarvestAiEditAlertClaims).to have_received(:new).with(alert)
  end

  it 'logs and skips an alert that raises, without aborting the batch' do
    alert # rev 100, lower id → processed first
    create(:ai_edit_alert, article:, revision_id: 300,
                           details: { article_title: 'Another_Article' })
    allow(Sentry).to receive(:capture_exception)
    call = 0
    allow(HarvestAiEditAlertClaims).to receive(:new) do
      call += 1
      raise 'boom' if call == 1
      instance_double(HarvestAiEditAlertClaims, claims: [instance_double(VerificationClaim)])
    end
    harvest = described_class.new
    expect(harvest.errors).to eq(1)
    expect(harvest.processed).to eq(1)
    expect(harvest.harvested).to eq(1)
    expect(Sentry).to have_received(:capture_exception)
  end

  it 'skips non-mainspace alerts via the title-based check' do
    create(:ai_edit_alert, article:, revision_id: 200,
                           details: { article_title: 'Draft:Quantum_memristor' })
    stub_harvester(5)
    harvest = described_class.new
    expect(harvest.skipped).to eq(1)
    expect(harvest.processed).to eq(0)
    expect(HarvestAiEditAlertClaims).not_to have_received(:new)
  end
end
