# frozen_string_literal: true

require 'rails_helper'

describe BuildAiDetectionSampleFromUrls do
  let(:text) { (['Prose added to the article during the course.'] * 60).join(' ') }
  let(:diff_url) { 'https://en.wikipedia.org/w/index.php?diff=1016458317&oldid=998714259' }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  before do
    allow(GetRevisionPlaintext).to receive(:new)
      .and_return(instance_double(GetRevisionPlaintext, plain_text: text))
  end

  it 'creates a unit per URL with the added text and the given attributes' do
    builder = described_class.new(
      sample_name: 'march',
      rows: [{ url: diff_url, ground_truth: 'human_pre_llm', campaign_slug: 'spring_2021',
               metadata: { 'character_sum' => 4000 } }]
    )

    expect(GetRevisionPlaintext).to have_received(:new)
      .with(1016458317, enwiki, diff_mode: true, from_rev: 998714259)
    unit = builder.created.first
    expect(builder.summary).to include(created: 1, skipped: 0, existing: 0)
    expect(unit).to have_attributes(sample_name: 'march', wiki_id: enwiki.id,
                                    rev_id: 1016458317, from_rev_id: 998714259,
                                    diff_mode: true, url: diff_url,
                                    ground_truth: 'human_pre_llm',
                                    campaign_slug: 'spring_2021', plain_text: text)
    expect(unit.metadata).to eq('character_sum' => 4000)
  end

  it 'fetches the whole revision for an oldid-only URL' do
    described_class.new(sample_name: 'march',
                        rows: [{ url: 'https://en.wikipedia.org/w/index.php?oldid=1009773007' }])

    expect(GetRevisionPlaintext).to have_received(:new)
      .with(1009773007, enwiki, diff_mode: false, from_rev: nil)
    expect(AiDetectionSample.last.diff_mode).to be false
  end

  it 'does not add the same unit to a sample twice' do
    described_class.new(sample_name: 'march', rows: [{ url: diff_url }])
    builder = described_class.new(sample_name: 'march', rows: [{ url: diff_url }])

    expect(AiDetectionSample.count).to eq(1)
    expect(builder.summary).to include(created: 0, existing: 1)
  end

  it 'skips URLs without a revision and texts that are too short' do
    allow(GetRevisionPlaintext).to receive(:new)
      .and_return(instance_double(GetRevisionPlaintext, plain_text: 'short'))

    builder = described_class.new(
      sample_name: 'march',
      rows: [{ url: 'https://en.wikipedia.org/wiki/Some_Title' }, { url: diff_url }]
    )

    expect(AiDetectionSample.count).to eq(0)
    expect(builder.skipped.map { |s| s[:reason] }).to eq(['no revision in url', 'not enough text'])
  end

  it 'skips a unit whose text cannot be fetched' do
    allow(GetRevisionPlaintext).to receive(:new).and_raise(MediawikiApi::ApiError.new(nil))

    builder = described_class.new(sample_name: 'march', rows: [{ url: diff_url }])

    expect(builder.skipped.first[:reason]).to include('MediawikiApi::ApiError')
  end

  describe '.from_csv' do
    let(:csv_path) { Rails.root.join('spec/fixtures/files/detector_comparison_march_2026.csv') }

    it 'takes the url, ground truth and campaign columns and keeps the rest as metadata' do
      builder = described_class.from_csv(sample_name: 'march', path: csv_path,
                                         url_column: 'cumulative_diff',
                                         ground_truth: 'experiment_ai')

      expect(builder.created.count).to eq(3)
      unit = builder.created.first
      expect(unit.ground_truth).to eq('experiment_ai')
      expect(unit.metadata).to include('term' => 'spring_2021',
                                       'pangram_max_likelihood' => '0.00463095845397896',
                                       'imported_from' => 'detector_comparison_march_2026.csv')
      expect(unit.metadata).not_to have_key('cumulative_diff')
    end
  end
end
