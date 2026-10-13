# frozen_string_literal: true

require 'rails_helper'

describe SummarizeDetectorComparison do
  include_context 'detector comparison data'

  let(:result) { described_class.new.result }
  let(:units) { result[:units].index_by { |unit| unit[:id] } }

  it 'leaves out the runs that browsed through workspace apps' do
    apps = AiDetectionSample.create!(
      sample_name: 'generated_stratified_2026_10', plain_text: "Apps #{generated_text}",
      ground_truth: 'ai', provenance: 'synthetic',
      factors: { 'model' => 'gpt-6-astra', 'topic' => 'Glacial stream' },
      metadata: { 'condition' => 'assignment_apps_web' }
    )
    expect(units.keys).not_to include(apps.id)
  end

  it 'lists generated texts, the Agpedia article on their topics and the paired human texts' do
    expect(units.keys).to contain_exactly(generated.id, human.id, agpedia_article.id,
                                          article_after_term.id)
    expect(units[generated.id]).to include(sample: 'generated_stratified_2026_10',
                                           condition: 'assignment', paired_unit_id: human.id,
                                           words: generated.word_count)
    expect(units[generated.id][:factors]).to include('model' => 'gpt-6-astra')
  end

  it "lists each strategy's prompts with the topic's name as a placeholder" do
    expect(result[:prompts]['assignment']).to eq(['Assigned article: {topic}',
                                                  "Current article:\n\n{prior_article}",
                                                  'Start drafting your contributions'])
  end

  it 'gives each detector its verdict and scores, with the alert rule for Pangram' do
    scores = units[generated.id][:scores]

    expect(scores.keys).to contain_exactly('Pangram 4', 'Originality AI Allowance 40',
                                           'Open Pangram EditLens Llama')
    expect(scores['Pangram 4']).to include(label: 'Mixed', alert: true, max: 0.95)
    expect(scores['Originality AI Allowance 40']).to include(label: 'AI', document: 0.99)
    expect(scores['Originality AI Allowance 40']).not_to have_key(:alert)
    expect(scores['Open Pangram EditLens Llama']).to include(label: 'AI-edited 1')
  end

  it 'counts any verdict short of human as a detection' do
    scores = units[generated.id][:scores]

    expect(scores.values.pluck(:flagged)).to all(be(true))
    expect(units[human.id][:scores]['Pangram 4']).to include(label: 'Human', flagged: false)
  end

  it "counts a detector's result on an identical copy of a text" do
    repeated_baseline.revision_ai_scores.create!(
      check_type: 'Originality AI Allowance 40', check_origin: 'detector_comparison',
      avg_ai_likelihood: 0.0, max_ai_likelihood: 0.1,
      details: { 'results' => { 'ai' => originality_ai_result.merge(
        'classification' => { 'AI' => 0, 'Original' => 1 },
        'confidence' => { 'AI' => 0.01, 'Original' => 0.99 }
      ) } }
    )
    expect(units[human.id][:scores]['Originality AI Allowance 40'])
      .to include(label: 'Original', flagged: false)
  end

  it 'rebuilds when a score changes within the same second as the newest change' do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    moment = Time.zone.parse('2026-10-13 12:00:00.1')
    AiDetectionSample.update_all(updated_at: moment)
    RevisionAiScore.update_all(updated_at: moment)
    described_class.new
    pangram = generated.revision_ai_scores.find_by(check_type: 'Pangram 4')
    travel_to(moment + 0.5.seconds, with_usec: true) do
      pangram.update!(details: pangram.details.merge('prediction_short' => 'AI'))
    end

    rebuilt = described_class.new.result[:units].find { |unit| unit[:id] == generated.id }
    expect(rebuilt[:scores]['Pangram 4']).to include(label: 'AI')
  end
end
