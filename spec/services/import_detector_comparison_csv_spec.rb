# frozen_string_literal: true

require 'rails_helper'

describe ImportDetectorComparisonCsv do
  let(:path) { Rails.root.join('spec/fixtures/files/detector_comparison_march_2026.csv') }
  let(:text) { (['Prose added to the article over the course.'] * 60).join(' ') }

  before do
    allow(GetRevisionPlaintext).to receive(:new)
      .and_return(instance_double(GetRevisionPlaintext, plain_text: text))
  end

  it 'creates the units and the scores the CSV already holds' do
    importer = described_class.new(sample_name: 'march', path:, pangram_version: '3.2')

    expect(importer.builder.created.count).to eq(3)
    expect(importer.imported).to eq(6)
    unit = AiDetectionSample.find_by(rev_id: 1016458317)
    expect(unit).to have_attributes(campaign_slug: 'spring_2021', ground_truth: 'human_pre_llm',
                                    from_rev_id: 998714259)
    expect(unit.metadata).to eq('imported_from' => 'detector_comparison_march_2026.csv')
    expect(unit.revision_ai_scores.pluck(:check_type)).to contain_exactly(
      'Pangram 3', 'Originality Turbo', 'Originality Academic'
    )
    expect(AiDetectionSample.find_by(rev_id: 1009773007).revision_ai_scores).to be_empty
    expect(AiDetectionSample.find_by(rev_id: 1315039613).ground_truth).to be_nil
  end

  it 'fills the summary with the CSV metrics using each vendor\'s conventions' do
    described_class.new(sample_name: 'march', path:, pangram_version: '3.2')
    unit = AiDetectionSample.find_by(rev_id: 1315039613)

    pangram = unit.revision_ai_scores.find_by(check_type: 'Pangram 3')
    expect(pangram).to have_attributes(max_ai_likelihood: 0.99, avg_ai_likelihood: 0.75,
                                       check_origin: 'detector_comparison')
    expect(pangram.details['summary']).to include(
      'vendor' => 'pangram', 'model_version' => '3.2', 'max_score' => 0.99,
      'mean_window_score' => 0.75, 'fraction_ai' => 0.8, 'fraction_mixed' => 0.2,
      'fraction_human' => 0.0, 'document_score' => nil, 'label' => nil
    )

    turbo = unit.revision_ai_scores.find_by(check_type: 'Originality Turbo')
    expect(turbo.max_ai_likelihood).to eq(1.0)
    expect(turbo.avg_ai_likelihood).to be_within(0.0001).of(0.5917)
    expect(turbo.details['summary']).to include('label' => 'AI', 'document_score' => 0.5917,
                                                'mean_window_score' => 0.563942655050798)
    academic = unit.revision_ai_scores.find_by(check_type: 'Originality Academic')
    expect(academic.details['summary']['label']).to eq('Original')
  end

  it 'is idempotent' do
    described_class.new(sample_name: 'march', path:)
    described_class.new(sample_name: 'march', path:)

    expect(AiDetectionSample.count).to eq(3)
    expect(RevisionAiScore.count).to eq(6)
  end
end
