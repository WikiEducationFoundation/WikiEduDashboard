# frozen_string_literal: true

require 'rails_helper'

describe ImportOfflineDetectorScores do
  let(:text) { (['Prose about a village and its river crossing.'] * 60).join(' ') }
  let(:sha) { Digest::SHA256.hexdigest(text) }
  let(:path) { Rails.root.join('tmp/import_offline_detector_scores_spec.csv') }
  let!(:unit) { AiDetectionSample.create!(sample_name: 'generated', plain_text: text) }
  let!(:same_text) { AiDetectionSample.create!(sample_name: 'subset', plain_text: text) }

  def write_csv(rows)
    CSV.open(path, 'w') do |csv|
      csv << %w[text_sha256 check_type vendor model_version scored_at error label document_score
                max_score mean_window_score window_count]
      rows.each { |row| csv << row }
    end
  end

  after { FileUtils.rm_f(path) }

  it 'adds a score with a typed summary to every unit with the text' do
    write_csv([[sha, 'Open Pangram EditLens Llama', 'open_pangram', 'b5f8044f', '2026-10-12', nil,
                'AI', '0.91', '0.97', '0.88', '2']])

    importer = described_class.new(path:)

    expect(importer.imported).to eq(2)
    score = unit.revision_ai_scores.find_by(check_type: 'Open Pangram EditLens Llama')
    expect(score.check_origin).to eq('detector_comparison')
    expect(score.avg_ai_likelihood).to eq(0.91)
    expect(score.max_ai_likelihood).to eq(0.97)
    expect(score.details['summary']).to include('vendor' => 'open_pangram', 'label' => 'AI',
                                                'document_score' => 0.91, 'window_count' => 2,
                                                'fraction_ai' => nil)
    expect(same_text.revision_ai_scores.count).to eq(1)
  end

  it 'updates rows on a second import, and skips failed and unmatched rows' do
    write_csv([[sha, 'Open Pangram EditLens Llama', 'open_pangram', 'v1', nil, nil,
                'Human', '0.1', '0.2', '0.1', '1']])
    described_class.new(path:)
    write_csv([[sha, 'Open Pangram EditLens Llama', 'open_pangram', 'v2', nil, nil,
                'AI', '0.9', '0.95', '0.9', '1'],
               [sha, 'Open Pangram EditLens RoBERTa', 'open_pangram', 'v2', nil, 'out of memory',
                nil, nil, nil, nil, nil],
               ['0' * 64, 'Open Pangram EditLens Llama', 'open_pangram', 'v2', nil, nil,
                'AI', '0.9', '0.95', '0.9', '1']])

    importer = described_class.new(path:)

    expect(importer.unmatched).to eq(1)
    expect(unit.revision_ai_scores.count).to eq(1)
    expect(unit.revision_ai_scores.first.details['summary']['model_version']).to eq('v2')
  end
end
