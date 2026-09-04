# frozen_string_literal: true

require 'rails_helper'

describe BuildAiDetectionSampleFromRows do
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
      rows: [{ url: diff_url, ground_truth: 'human', provenance: 'pre_llm_term',
               campaign_slug: 'spring_2021', notes: 'bibliography page',
               factors: { 'topic' => 'Bees' }, metadata: { 'character_sum' => 4000 } }]
    )

    expect(GetRevisionPlaintext).to have_received(:new)
      .with(1016458317, enwiki, diff_mode: true, from_rev: 998714259)
    unit = builder.created.first
    expect(builder.summary).to include(created: 1, skipped: 0, existing: 0)
    expect(unit).to have_attributes(sample_name: 'march', wiki_id: enwiki.id,
                                    rev_id: 1016458317, from_rev_id: 998714259,
                                    diff_mode: true, url: diff_url,
                                    ground_truth: 'human', provenance: 'pre_llm_term',
                                    notes: 'bibliography page',
                                    campaign_slug: 'spring_2021', plain_text: text)
    expect(unit.factors).to eq('topic' => 'Bees')
    expect(unit.metadata).to eq('character_sum' => 4000)
  end

  it 'creates a text unit when a row carries text, keeping the url as a reference' do
    builder = described_class.new(
      sample_name: 'synthetic',
      rows: [{ text:, url: 'https://example.org/generated/1', ground_truth: 'ai',
               provenance: 'synthetic', factors: { 'model' => 'gpt-5', 'prompt' => 'naive' } }]
    )

    expect(GetRevisionPlaintext).not_to have_received(:new)
    unit = builder.created.first
    expect(unit).to have_attributes(rev_id: nil, wiki_id: nil, url: 'https://example.org/generated/1',
                                    ground_truth: 'ai', provenance: 'synthetic', plain_text: text)
    expect(unit.factors).to eq('model' => 'gpt-5', 'prompt' => 'naive')
  end

  it 'does not add the same text twice to a sample' do
    described_class.new(sample_name: 'synthetic', rows: [{ text: }])
    builder = described_class.new(sample_name: 'synthetic', rows: [{ text: }])

    expect(AiDetectionSample.count).to eq(1)
    expect(builder.summary).to include(created: 0, existing: 1)
  end

  it 'fetches the whole revision for an oldid-only URL' do
    described_class.new(sample_name: 'march',
                        rows: [{ url: 'https://en.wikipedia.org/w/index.php?oldid=1009773007' }])

    expect(GetRevisionPlaintext).to have_received(:new)
      .with(1009773007, enwiki, diff_mode: false, from_rev: nil)
    expect(AiDetectionSample.last.diff_mode).to be false
  end

  it 'does not add the same revision unit to a sample twice' do
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
      rows: [{ url: 'https://en.wikipedia.org/wiki/Some_Title' }, { url: diff_url },
             { text: 'tiny' }]
    )

    expect(AiDetectionSample.count).to eq(0)
    expect(builder.skipped.map { |s| s[:reason] })
      .to eq(['no revision in url', 'not enough text', 'not enough text'])
  end

  it 'skips a unit whose text cannot be fetched' do
    allow(GetRevisionPlaintext).to receive(:new).and_raise(MediawikiApi::ApiError.new(nil))

    builder = described_class.new(sample_name: 'march', rows: [{ url: diff_url }])

    expect(builder.skipped.first[:reason]).to include('MediawikiApi::ApiError')
  end

  describe '.from_csv' do
    let(:march_csv) { Rails.root.join('spec/fixtures/files/detector_comparison_march_2026.csv') }

    it 'takes the url column and keeps the other columns as metadata' do
      builder = described_class.from_csv(sample_name: 'march', path: march_csv,
                                         url_column: 'cumulative_diff',
                                         ground_truth: 'human', provenance: 'pre_llm_term')

      expect(builder.created.count).to eq(3)
      unit = builder.created.first
      expect(unit).to have_attributes(ground_truth: 'human', provenance: 'pre_llm_term')
      expect(unit.metadata).to include('term' => 'spring_2021',
                                       'pangram_max_likelihood' => '0.00463095845397896',
                                       'imported_from' => 'detector_comparison_march_2026.csv')
      expect(unit.metadata).not_to have_key('cumulative_diff')
      expect(unit.factors).to eq({})
    end

    it 'reads text units with per-row attributes and factor_ columns' do
      path = Rails.root.join('tmp/exemplars_spec.csv')
      CSV.open(path, 'w') do |csv|
        csv << %w[text ground_truth provenance notes factor_topic factor_model factor_prompt source]
        csv << [text, 'ai', 'synthetic', 'naive prompt', 'Bees', 'gpt-5', 'naive', 'generated']
        csv << ["#{text} again", '', '', '', 'Bees', '', '', 'copied']
      end

      builder = described_class.from_csv(sample_name: 'exemplars', path:,
                                         ground_truth: 'ai_assisted', provenance: 'experiment')

      generated, copied = builder.created
      expect(generated).to have_attributes(ground_truth: 'ai', provenance: 'synthetic',
                                           notes: 'naive prompt', rev_id: nil)
      expect(generated.factors).to eq('topic' => 'Bees', 'model' => 'gpt-5', 'prompt' => 'naive')
      expect(generated.metadata).to eq('source' => 'generated',
                                       'imported_from' => 'exemplars_spec.csv')
      expect(copied).to have_attributes(ground_truth: 'ai_assisted', provenance: 'experiment',
                                        notes: nil)
      expect(copied.factors).to eq('topic' => 'Bees')
    ensure
      FileUtils.rm_f(path)
    end
  end
end
