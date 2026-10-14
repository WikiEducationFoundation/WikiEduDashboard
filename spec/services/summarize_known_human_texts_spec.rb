# frozen_string_literal: true

require 'rails_helper'

describe SummarizeKnownHumanTexts do
  include_context 'detector comparison data'

  let(:result) { described_class.new.result }
  let(:units) { result[:units].index_by { |unit| unit[:id] } }

  it 'lists the pre-ChatGPT English Wikipedia texts of the baseline samples' do
    french = AiDetectionSample.create!(
      sample_name: 'terms_baseline_extra', plain_text: "Un étudiant a écrit #{human_text}",
      ground_truth: 'human', provenance: 'pre_llm_term',
      url: 'https://fr.wikipedia.org/w/index.php?diff=40&oldid=30'
    )
    expect(units.keys).to eq([human.id])
    expect(units.keys).not_to include(french.id, repeated_baseline.id, article_after_term.id)
  end

  it 'leaves out redirect pages' do
    AiDetectionSample.create!(
      sample_name: 'terms_baseline_extra', plain_text: "Redirect to:\nWomen in positions of power",
      ground_truth: 'human', provenance: 'pre_llm_term',
      url: 'https://en.wikipedia.org/w/index.php?oldid=950786347'
    )
    expect(units.keys).to eq([human.id])
  end

  it 'gives each text its term, title and every detector, counting results on copies' do
    article = create(:article, title: 'Glacial_stream')
    human.update!(campaign_slug: 'spring_2021', article_id: article.id)
    repeated_baseline.revision_ai_scores.create!(
      check_type: 'Originality AI Allowance 15', check_origin: 'detector_comparison',
      avg_ai_likelihood: 0.99, max_ai_likelihood: 1.0,
      details: { 'results' => { 'ai' => originality_ai_result } }
    )
    unit = units[human.id]

    expect(unit).to include(term: 'spring_2021', title: 'Glacial stream')
    expect(unit[:scores]['Pangram 4']).to include(label: 'Human', flagged: false)
    expect(unit[:scores]['Originality AI Allowance 15']).to include(label: 'AI', flagged: true)
  end
end
