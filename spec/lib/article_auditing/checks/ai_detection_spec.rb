# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"
require "#{Rails.root}/lib/article_auditing/registry"

describe ArticleAuditing::Checks::AiDetection do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:prose) { 'Some prose. ' * 60 }
  let(:context) { instance_double(ArticleAuditing::Context, prose_text: prose, wiki:, mw_rev_id: 555) }
  let(:score) { 1.0 }
  let(:response) do
    { 'stage' => 'STAGE_SUCCESS', 'text' => prose, 'version' => '4.0', 'headline' => 'AI Generated',
      'prediction' => 'AI.', 'fraction_ai' => 0.8, 'fraction_ai_assisted' => 0.2,
      'fraction_human' => 0.0,
      'windows' => [{ 'text' => 'w', 'label' => 'AI-Generated', 'ai_assistance_score' => score,
                      'confidence' => 'High', 'word_count' => 300 }],
      'dashboard_link' => 'https://www.pangram.com/history/abc' }
  end
  let(:client) { double('PangramApi', inference: response) } # rubocop:disable RSpec/VerifiedDoubles

  before do
    allow(AiDetector.for(described_class::DETECTOR_KEY)).to receive(:client).and_return(client)
  end

  it 'flags likely AI text, records a RevisionAiScore and summarizes the result' do
    output = described_class.new.run(context)
    expect(output.findings.first).to include('severity' => 'must_fix', 'category' => 'external')
    score_row = RevisionAiScore.last
    expect(score_row).to have_attributes(revision_id: 555, check_origin: 'article_audit',
                                         max_ai_likelihood: 1.0)
    expect(output.artifacts['ai_detection']).to include('revision_ai_score_id' => score_row.id,
                                                        'share_link' => 'https://www.pangram.com/history/abc')
    expect(client).to have_received(:inference).with(prose)
  end

  context 'when the text is probably human-written' do
    let(:score) { 0.1 }

    it 'returns no findings but still summarizes the score' do
      output = described_class.new.run(context)
      expect(output.findings).to be_empty
      expect(output.artifacts['ai_detection']['max_ai_likelihood']).to eq(0.1)
    end
  end

  context 'when the prose is too short to score' do
    let(:prose) { 'Short.' }

    it 'skips the detector' do
      expect(described_class.new.run(context).usage).to include('skipped' => 'text too short')
      expect(client).not_to have_received(:inference)
    end
  end

  it 'applies only when a Pangram key is configured' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('pangram_api_key').and_return(nil)
    expect(described_class.new.applies_to?(context)).to be(false)
    allow(ENV).to receive(:[]).with('pangram_api_key').and_return('key')
    expect(described_class.new.applies_to?(context)).to be(true)
  end
end
