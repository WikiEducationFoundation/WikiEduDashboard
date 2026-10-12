# frozen_string_literal: true

require 'rails_helper'

describe SummarizeDetectorComparison do
  include_context 'detector comparison data'

  let(:result) { described_class.new.result }
  let(:units) { result[:units].index_by { |unit| unit[:id] } }

  it 'lists the known-AI units and their paired human texts, not retired units' do
    expect(units.keys).to contain_exactly(generated.id, human.id)
    expect(units[generated.id]).to include(sample: 'generated_stratified_2026_10',
                                           condition: 'assignment', paired_unit_id: human.id,
                                           words: generated.word_count)
    expect(units[generated.id][:factors]).to include('model' => 'gpt-6-astra')
  end

  it 'gives each detector its verdict and scores, with the alert rule for Pangram' do
    scores = units[generated.id][:scores]

    expect(scores.keys).to contain_exactly('Pangram 4', 'Originality AI Allowance 40',
                                           'Open Pangram EditLens Llama')
    expect(scores['Pangram 4']).to include(label: 'Mixed', flagged: false, alert: true, max: 0.95)
    expect(scores['Originality AI Allowance 40']).to include(label: 'AI', flagged: true,
                                                             document: 0.99)
    expect(scores['Originality AI Allowance 40']).not_to have_key(:alert)
    expect(scores['Open Pangram EditLens Llama']).to include(label: 'AI-edited 1', flagged: false)
  end

  it 'counts each baseline text once per detector' do
    expect(result[:baseline]['Pangram 4']).to eq(texts: 1, flagged: 0, alerts: 0)
  end
end
