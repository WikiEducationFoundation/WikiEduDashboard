# frozen_string_literal: true

require 'rails_helper'

describe ExportAiDetectionComparison do
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:text) { (['Prose about a village and its river crossing.'] * 60).join(' ') }
  let(:unit) do
    AiDetectionSample.create!(sample_name: 'march', plain_text: text, wiki_id: enwiki.id,
                              rev_id: 500, from_rev_id: 400, campaign_slug: 'spring_2021',
                              ground_truth: 'human_pre_llm', namespace: 0,
                              url: 'https://en.wikipedia.org/w/index.php?diff=500&oldid=400',
                              metadata: { 'character_sum' => 4000 })
  end
  let(:other_unit) { AiDetectionSample.create!(sample_name: 'other', plain_text: text) }

  before do
    unit.revision_ai_scores.create!(
      check_type: 'Pangram 4', check_origin: 'detector_comparison',
      avg_ai_likelihood: 0.6, max_ai_likelihood: 0.97,
      details: { 'version' => '4.0', 'prediction_short' => 'Mixed', 'fraction_ai' => 0.5,
                 'fraction_ai_assisted' => 0.2, 'fraction_human' => 0.3,
                 'windows' => [{ 'ai_assistance_score' => 0.97, 'is_humanized' => true,
                                 'humanizer_score' => 0.9 },
                               { 'ai_assistance_score' => 0.23, 'is_humanized' => false,
                                 'humanizer_score' => 0.1 }],
                 'dashboard_link' => 'https://www.pangram.com/history/abc' }
    )
    unit.revision_ai_scores.create!(
      check_type: 'Originality Turbo', check_origin: 'detector_comparison',
      avg_ai_likelihood: 0.16, max_ai_likelihood: 1.0,
      details: { 'summary' => DetectorSummary::KEYS.index_with(nil)
                                .merge('check_type' => 'Originality Turbo', 'max_score' => 1.0),
                 'imported_from' => 'march.csv' }
    )
    unit.revision_ai_scores.create!(
      check_type: 'Originality AI Allowance 40', check_origin: 'detector_comparison',
      details: { 'error' => 'OriginalityApi::RequestError', 'message' => 'HTTP 402' }
    )
    other_unit.revision_ai_scores.create!(check_type: 'Pangram 4', avg_ai_likelihood: 0.1,
                                          max_ai_likelihood: 0.1, details: { 'windows' => [] })
  end

  it 'produces one long-format row per unit and detector' do
    rows = described_class.new(sample_names: ['march']).rows

    expect(rows.count).to eq(3)
    pangram = rows.find { |row| row['check_type'] == 'Pangram 4' }
    expect(pangram).to include('sample_name' => 'march', 'unit_id' => unit.id,
                               'wiki' => 'en.wikipedia.org', 'rev_id' => 500, 'from_rev_id' => 400,
                               'ground_truth' => 'human_pre_llm', 'word_count' => 480,
                               'metadata' => '{"character_sum":4000}',
                               'vendor' => 'pangram', 'model_version' => '4.0', 'label' => 'Mixed',
                               'max_score' => 0.97, 'mean_window_score' => 0.6, 'window_count' => 2,
                               'windows_above_0_9' => 1, 'humanized_window_count' => 1)
  end

  it 'uses the stored summary for imported rows and flags failed rows' do
    rows = described_class.new(sample_names: ['march']).rows

    imported = rows.find { |row| row['check_type'] == 'Originality Turbo' }
    expect(imported['max_score']).to eq(1.0)
    failed = rows.find { |row| row['check_type'] == 'Originality AI Allowance 40' }
    expect(failed['error']).to eq('HTTP 402')
    expect(failed['max_score']).to be_nil
  end

  it 'writes a CSV with a fixed header for every sample when none are named' do
    path = Rails.root.join('tmp/detector_comparison_export_spec.csv')
    csv = described_class.new.to_csv(path)

    parsed = CSV.parse(csv, headers: true)
    expect(parsed.headers).to eq(described_class.headers)
    expect(parsed.count).to eq(4)
    expect(File.read(path)).to eq(csv)
  ensure
    FileUtils.rm_f(path)
  end
end
