# frozen_string_literal: true

require 'rails_helper'

describe PublishDetectorComparison do
  include_context 'published detector comparison data'

  def published_json(name)
    JSON.parse(described_class.published_file(name).read)
  end

  it 'has nothing to serve before the first publication' do
    expect(described_class.published_file('topics')).to be_nil
    expect(described_class.manifest).to be_nil
  end

  it 'publishes both datasets, every unit they list and the size of each dataset' do
    described_class.new

    expect(published_json('topics')['units'].map { |unit| unit['id'] })
      .to contain_exactly(generated.id, human.id, agpedia_article.id, article_after_term.id)
    expect(published_json('known_human')['units'].map { |unit| unit['id'] }).to eq([human.id])
    expect(published_json("units/#{human.id}")['text']).to eq(human_text)
    expect(described_class.published_file("units/#{retired.id}")).to be_nil
    expect(described_class.manifest['counts']).to eq('topics' => 4, 'known_human' => 1)
  end

  it 'writes a gzipped copy of each file' do
    described_class.new
    file = described_class.published_file('topics')

    expect(ActiveSupport::Gzip.decompress(File.binread("#{file}.gz"))).to eq(file.read)
  end

  it 'serves a new publication once it is complete, keeping the latest few' do
    first = described_class.new
    generated.revision_ai_scores.find_by(check_type: 'Pangram 4').update!(avg_ai_likelihood: nil)
    publications = Array.new(described_class::KEEP) do |minutes|
      travel_to((minutes + 1).minutes.from_now) { described_class.new }
    end

    expect(described_class.published_file('topics').realpath.dirname)
      .to eq(publications.last.path.realpath)
    expect(first.path).not_to exist
    expect(publications.map(&:path)).to all(exist)
    unit = published_json('topics')['units'].find { |row| row['id'] == generated.id }
    expect(unit['scores']).not_to have_key('Pangram 4')
  end

  it 'keeps serving the previous publication when a publication fails partway' do
    first = described_class.new
    allow(DescribeDetectorComparisonUnit).to receive(:new).and_raise('unit failed')

    expect { travel_to(1.minute.from_now) { described_class.new } }.to raise_error('unit failed')
    expect(described_class.published_file('topics').realpath.dirname).to eq(first.path.realpath)
  end
end
