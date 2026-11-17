# frozen_string_literal: true

require 'rails_helper'

describe ExportDetectorComparisonScores do
  include_context 'detector comparison data'

  let(:path) { Rails.root.join('tmp', 'detector_comparison_scores_spec.jsonl') }

  after { FileUtils.rm_f(path) }

  it 'writes each comparison row of the given detectors as a line of JSON' do
    export = described_class.new(path, check_types: ['Pangram 4'])

    rows = File.readlines(path).map { |line| JSON.parse(line) }
    expect(export.count).to eq(3)
    expect(rows.pluck('sample_name'))
      .to contain_exactly('generated_stratified_2026_10', 'terms_2021_2025_march',
                          'originality_2026_09')
    expect(rows.first).to include('check_type' => 'Pangram 4', 'avg' => 0.6, 'max' => 0.95,
                                  'text_sha256' => generated.text_sha256)
    expect(rows.first['details']['windows']).to be_present
  end

  it 'leaves out rows that are not detector comparison scores' do
    RevisionAiScore.create!(check_type: 'Pangram 4', check_origin: 'ai_tool',
                            avg_ai_likelihood: 0.5, max_ai_likelihood: 0.5)

    expect(described_class.new(path, check_types: ['Pangram 4']).count).to eq(3)
  end
end
