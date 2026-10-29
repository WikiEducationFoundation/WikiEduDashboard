# frozen_string_literal: true

require 'rails_helper'

describe CheckOriginEditsWithPangram do
  let(:wiki) { Wiki.default_wiki }
  let(:course) { create(:course) }
  let(:student) { create(:user, username: 'Student') }
  let(:article) { create(:article, title: 'Kingdom_of_Aksum', mw_page_id: 20609804) }
  let(:passages) { ['Stone Age artifacts have been unearthed at Gobedra.'] }
  let(:attributes) do
    { 'mw_rev_id' => 1382181955, 'wiki_id' => wiki.id, 'article_id' => article.id,
      'course_id' => course.id, 'user_id' => student.id, 'article_title' => 'Kingdom of Aksum',
      'parent_rev_id' => 1374239548, 'passages' => passages }
  end
  let(:client) { instance_double(PangramApi) }

  def origin(rev_id, timestamp, words)
    { rev_id:, username: "Editor#{rev_id}", timestamp: Time.zone.parse(timestamp), words: }
  end

  def pangram_response(score)
    { 'windows' => [{ 'ai_assistance_score' => score, 'text' => 'window' }],
      'headline' => 'AI Generated', 'dashboard_link' => "https://www.pangram.com/history/#{score}" }
  end

  def stored_score(rev_id, score, check_origin: nil)
    create(:revision_ai_score, revision_id: rev_id, wiki:, article:, check_type: 'Pangram 4',
                               check_origin:, avg_ai_likelihood: score, max_ai_likelihood: score,
                               details: pangram_response(score))
  end

  let(:origins) do
    [origin(101, '2024-07-01', 49), origin(102, '2023-12-27', 29),
     origin(103, '2007-11-27', 9), origin(104, '2026-02-13', 8),
     origin(105, '2025-01-08', 2)]
  end

  before do
    # The student's edit, as CheckRevisionWithPangram recorded it.
    stored_score(1382181955, 0.99, check_origin: RevisionAiScore::COURSE_UPDATE_ORIGIN)
    allow(FindOriginRevisions).to receive(:new)
      .with(wiki:, article:, rev_id: 1374239548, passages:)
      .and_return(instance_double(FindOriginRevisions, origins:))
    allow(GetRevisionPlaintext).to receive(:new)
      .and_return(instance_double(GetRevisionPlaintext, plain_text: 'x' * 600))
    allow(AiDetector.for(described_class::DETECTOR_KEY)).to receive(:client).and_return(client)
    allow(client).to receive(:inference).and_return(pangram_response(0.99))
    allow_any_instance_of(PreexistingAiTextAlert).to receive(:send_alert_emails)
    allow_any_instance_of(AiEditAlert).to receive(:send_alert_emails)
  end

  it 'checks up to three origin edits made since ChatGPT was released' do
    checked = described_class.new(attributes).checked_origins.map { |edit| edit[:rev_id] }
    expect(checked).to eq([101, 102, 104])
    expect(client).to have_received(:inference).exactly(3).times
  end

  it 'records each new score as an origin edit check' do
    described_class.new(attributes)
    scores = RevisionAiScore.where(check_origin: RevisionAiScore::ORIGIN_EDIT_ORIGIN)
    expect(scores.pluck(:revision_id)).to contain_exactly(101, 102, 104)
    expect(scores.pluck(:course_id).uniq).to eq([course.id])
  end

  it 'reuses a stored score instead of checking an edit again' do
    stored_score(101, 0.1)
    result = described_class.new(attributes)
    expect(client).to have_received(:inference).twice
    expect(result.checked_origins.first[:max_ai_likelihood]).to eq(0.1)
  end

  it 'creates only a pre-existing AI text alert when an origin edit is flagged' do
    described_class.new(attributes)
    alert = PreexistingAiTextAlert.last
    expect(alert.revision_id).to eq(1382181955)
    expect(alert.user).to eq(student)
    expect(alert.details[:headline_result]).to eq('AI Generated')
    expect(alert.flagged_origin_edits.size).to eq(3)
    expect(AiEditAlert.count).to eq(0)
  end

  it 'creates the regular alert instead when no origin edit is flagged' do
    allow(client).to receive(:inference).and_return(pangram_response(0.2))
    described_class.new(attributes)
    expect(PreexistingAiTextAlert.count).to eq(0)
    expect(AiEditAlert.last.revision_id).to eq(1382181955)
    expect(AiEditAlert.last.details[:flagged_text_preexisting]).to be true
  end

  it 'creates the regular alert when the flagged origin edits already had alerts' do
    { 101 => 0.99, 102 => 0.1, 104 => 0.1 }.each { |rev_id, score| stored_score(rev_id, score) }
    create(:ai_edit_alert, revision_id: 101)
    described_class.new(attributes)
    expect(PreexistingAiTextAlert.count).to eq(0)
    expect(AiEditAlert.where(revision_id: 1382181955).count).to eq(1)
  end

  it 'creates the regular alert when the origin edit checks fail' do
    allow(client).to receive(:inference).and_raise(PangramApi::TaskTimeout)
    expect(described_class.new(attributes).checked_origins).to be_empty
    expect(AiEditAlert.where(revision_id: 1382181955).count).to eq(1)
  end

  it 'creates the regular alert without checking origins when told to' do
    expect(FindOriginRevisions).not_to receive(:new)
    described_class.new(attributes, check_origins: false)
    expect(AiEditAlert.where(revision_id: 1382181955).count).to eq(1)
  end

  it 'does nothing when the edit already has an alert' do
    create(:preexisting_ai_text_alert, revision_id: 1382181955)
    expect(FindOriginRevisions).not_to receive(:new)
    described_class.new(attributes)
    expect(AiEditAlert.count).to eq(0)
  end
end
