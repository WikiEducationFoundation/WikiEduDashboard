# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_library/record"
require "#{Rails.root}/lib/claim_verification/claim"
require "#{Rails.root}/lib/claim_verification/citation"

describe ClaimLibrary::Record do
  it 'gives the same claim the same id every time' do
    expect(library_record.id).to eq(library_record.id)
    expect(library_record.id).to match(/\A\h{12}\z/)
  end

  it 'gives a different sentence a different id' do
    expect(library_record(sentence: 'Something else.').id).not_to eq(library_record.id)
  end

  it 'builds from an extracted claim and its citation' do
    claim = ClaimVerification::Claim.new(sentence: 'The site opened in 1990.',
                                         ref_ids: ['cite_note-a-1'],
                                         context: 'Early days. The site opened in 1990.')
    citation = ClaimVerification::Citation.new(ref_id: 'cite_note-a-1', cite_html: '<i>History</i>',
                                               cite_text: 'History', urls: ['https://example.com/h'],
                                               archive_urls: [])
    record = described_class.from_claim(claim, citation, wiki: 'en.wikipedia',
                                                         article_title: 'Example', mw_rev_id: 5)
    expect(record.sentence).to eq('The site opened in 1990.')
    expect(record.ref_id).to eq('cite_note-a-1')
    expect(record.source_url).to eq('https://example.com/h')
    expect(record.citation['offline']).to eq(false)
    expect(record).not_to be_judged
  end

  it 'survives a round trip through its hash form, judgment and source included' do
    record = judged_record
    record.source = ClaimLibrary::Source.read(url: record.source_url, read_from: 'https://copy',
                                              text: 'the text')
    restored = described_class.from_h(JSON.parse(JSON.generate(record.to_h)))
    expect(restored.id).to eq(record.id)
    expect(restored.judgment.verdict).to eq('full_support')
    expect(restored.source.read_from).to eq('https://copy')
    expect(restored.source.text).to be_nil
  end
end
