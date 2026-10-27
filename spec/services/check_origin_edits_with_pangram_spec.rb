# frozen_string_literal: true

require 'rails_helper'

describe CheckOriginEditsWithPangram do
  let(:wiki) { Wiki.default_wiki }
  let(:course) { create(:course) }
  let(:student) { create(:user, username: 'Student') }
  let(:article) { create(:article, title: 'Kingdom_of_Aksum', mw_page_id: 20609804) }
  let(:ai_edit_alert) do
    create(:ai_edit_alert, course:, user: student, article:, revision_id: 1382181955,
                           details: { article_title: 'Kingdom of Aksum' })
  end
  let(:passages) { ['Stone Age artifacts have been unearthed at Gobedra.'] }
  let(:client) { instance_double(PangramApi) }

  def origin(rev_id, timestamp, words)
    { rev_id:, username: "Editor#{rev_id}", timestamp: Time.zone.parse(timestamp), words: }
  end

  def pangram_response(score)
    { 'windows' => [{ 'ai_assistance_score' => score, 'text' => 'window' }],
      'dashboard_link' => "https://www.pangram.com/history/#{score}" }
  end

  let(:origins) do
    [origin(101, '2024-07-01', 49), origin(102, '2023-12-27', 29),
     origin(103, '2007-11-27', 9), origin(104, '2026-02-13', 8),
     origin(105, '2025-01-08', 2)]
  end

  before do
    allow(FindOriginRevisions).to receive(:new)
      .with(wiki:, article:, rev_id: 1374239548, passages:)
      .and_return(instance_double(FindOriginRevisions, origins:))
    allow(GetRevisionPlaintext).to receive(:new)
      .and_return(instance_double(GetRevisionPlaintext, plain_text: 'x' * 600))
    allow(AiDetector.for(described_class::DETECTOR_KEY)).to receive(:client).and_return(client)
    allow(client).to receive(:inference).and_return(pangram_response(0.99))
    allow_any_instance_of(PreexistingAiTextAlert).to receive(:send_alert_emails)
  end

  def check
    described_class.new(ai_edit_alert:, parent_rev_id: 1374239548, passages:)
  end

  it 'checks up to three origin edits made since ChatGPT was released' do
    checked = check.checked_origins.map { |edit| edit[:rev_id] }
    expect(checked).to eq([101, 102, 104])
    expect(client).to have_received(:inference).exactly(3).times
  end

  it 'records each new score as an origin edit check' do
    check
    scores = RevisionAiScore.where(check_origin: RevisionAiScore::ORIGIN_EDIT_ORIGIN)
    expect(scores.pluck(:revision_id)).to contain_exactly(101, 102, 104)
    expect(scores.pluck(:course_id).uniq).to eq([course.id])
  end

  it 'reuses a stored score instead of checking an edit again' do
    create(:revision_ai_score, revision_id: 101, wiki:, check_type: 'Pangram 4',
                               avg_ai_likelihood: 0.1, max_ai_likelihood: 0.1,
                               details: pangram_response(0.1))
    result = check
    expect(client).to have_received(:inference).twice
    expect(result.checked_origins.first[:max_ai_likelihood]).to eq(0.1)
  end

  it 'creates an alert for the student edit when an origin edit is flagged' do
    check
    alert = PreexistingAiTextAlert.last
    expect(alert.revision_id).to eq(1382181955)
    expect(alert.user).to eq(student)
    expect(alert.details[:ai_edit_alert_id]).to eq(ai_edit_alert.id)
    expect(alert.flagged_origin_edits.size).to eq(3)
  end

  it 'creates no alert when no origin edit is flagged' do
    allow(client).to receive(:inference).and_return(pangram_response(0.2))
    check
    expect(PreexistingAiTextAlert.count).to eq(0)
  end

  it 'creates no alert when the flagged origin edits already had alerts' do
    stored = { 101 => 0.99, 102 => 0.1, 104 => 0.1 }
    stored.each do |rev_id, score|
      create(:revision_ai_score, revision_id: rev_id, wiki:, check_type: 'Pangram 4',
                                 avg_ai_likelihood: score, max_ai_likelihood: score,
                                 details: pangram_response(score))
    end
    create(:ai_edit_alert, revision_id: 101)
    check
    expect(PreexistingAiTextAlert.count).to eq(0)
  end

  it 'does nothing when the student edit was already followed up' do
    create(:preexisting_ai_text_alert, revision_id: 1382181955)
    expect(FindOriginRevisions).not_to receive(:new)
    check
  end

  it 'skips an origin edit whose check fails' do
    allow(client).to receive(:inference).and_raise(PangramApi::TaskTimeout)
    expect(check.checked_origins).to be_empty
    expect(PreexistingAiTextAlert.count).to eq(0)
  end
end
