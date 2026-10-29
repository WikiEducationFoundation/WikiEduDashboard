# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'
require "#{Rails.root}/lib/claim_library/library"

describe ClaimLibrary::Library do
  around do |example|
    Dir.mktmpdir { |dir| @path = File.join(dir, 'library.jsonl'); example.run }
  end

  it 'starts empty when the file does not exist' do
    expect(described_class.new(@path).records).to be_empty
  end

  it 'adds only records it does not already hold' do
    library = described_class.new(@path)
    expect(library.add([library_record, library_record(sentence: 'Another.')])).to eq(2)
    expect(library.add([library_record])).to eq(0)
    expect(library.records.size).to eq(2)
  end

  it 'keeps judgments across a save and reload' do
    library = described_class.new(@path)
    library.add([judged_record, library_record(sentence: 'Unjudged.')])
    library.save

    reloaded = described_class.new(@path)
    expect(reloaded.judged.map(&:sentence)).to eq([judged_record.sentence])
    expect(reloaded.unjudged.map(&:sentence)).to eq(['Unjudged.'])
    expect(reloaded.find(judged_record.id).judgment.annotator).to eq('Moruri')
  end

  it 'writes one record per line' do
    library = described_class.new(@path)
    library.add([library_record, library_record(sentence: 'Another.')])
    library.save
    expect(File.readlines(@path).size).to eq(2)
  end
end
