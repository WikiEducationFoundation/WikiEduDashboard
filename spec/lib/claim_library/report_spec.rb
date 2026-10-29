# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_library/report"
require "#{Rails.root}/lib/claim_library/library"

describe ClaimLibrary::Report do
  let(:library) do
    library = ClaimLibrary::Library.new('/nonexistent/library.jsonl')
    unsupported = judged_record(verdict: 'unsupported', flags: ['misattribution'],
                                sentence: 'The committee called the Bill patriarchal.')
    library.add([judged_record, unsupported, library_record(sentence: 'Not yet judged.')])
    library
  end
  let(:markdown) { described_class.new(library).to_markdown }

  it 'counts what has been judged' do
    expect(markdown).to include('2 of 3 claims judged, from 1 article.')
    expect(markdown).to include('| full_support | 1 |')
    expect(markdown).to include('| unsupported | 1 |')
    expect(markdown).to include('| misattribution | 1 |')
  end

  it 'writes each judged claim with its reason and the passage it rests on' do
    expect(markdown).to include('## Surrogacy in India: unsupported')
    expect(markdown).to include('**Claim.** The committee called the Bill patriarchal.')
    expect(markdown).to include('> surrogacy generates US$2.3 billion annually')
    expect(markdown).to include('Judged by Moruri on')
  end

  it 'leaves unjudged claims out of the entries' do
    expect(markdown).not_to include('Not yet judged.')
  end
end
