# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'
require "#{Rails.root}/lib/claim_library/annotator"
require "#{Rails.root}/lib/claim_library/library"

describe ClaimLibrary::Annotator do
  around do |example|
    Dir.mktmpdir { |dir| @path = File.join(dir, 'library.jsonl'); example.run }
  end

  let(:library) { ClaimLibrary::Library.new(@path).tap { |l| l.add([library_record]) } }
  let(:source_text) { 'The Confederation of Indian Industry predicts US$2.3 billion annually.' }
  let(:fetcher) do
    source = ClaimLibrary::Source.read(url: library_record.source_url, read_from: 'https://copy',
                                       text: source_text)
    instance_double(ClaimLibrary::SourceFetcher, fetch: source)
  end
  let(:output) { StringIO.new }

  def run(*answers)
    input = StringIO.new("#{answers.join("\n")}\n")
    described_class.new(library:, fetcher:, annotator: 'Moruri', input:, output:).run
  end

  it 'shows the claim, the source and the likely passage before asking anything' do
    run('q')
    expect(output.string).to include(library_record.sentence)
    expect(output.string).to include('journal, read from https://copy')
    expect(output.string).to include('US$2.3 billion annually')
    expect(output.string).to include('1. full_support')
  end

  it 'records a judgment and saves the library' do
    recorded = run('2', 'One body, not industry groups.', 'predicts US$2.3 billion annually',
                   'true_but_unsupported')
    expect(recorded).to eq(1)
    judgment = ClaimLibrary::Library.new(@path).records.first.judgment
    expect(judgment.verdict).to eq('partial_support')
    expect(judgment.flags).to eq(['true_but_unsupported'])
    expect(judgment.annotator).to eq('Moruri')
  end

  it 'refuses a passage that is not in the source and asks again' do
    recorded = run('1', 'Reason.', 'thousands of clinics', '',
                   '1', 'Reason.', 'US$2.3 billion annually', '')
    expect(output.string).to include('passage was not found in the source text')
    expect(recorded).to eq(1)
  end

  it 'skips a claim on request and leaves it unjudged' do
    expect(run('s')).to eq(0)
    expect(ClaimLibrary::Library.new(@path).unjudged.size).to eq(1)
  end

  it 'stops on request' do
    library.add([library_record(sentence: 'Second claim.')])
    expect(run('q')).to eq(0)
    expect(output.string).not_to include('Second claim.')
  end
end
