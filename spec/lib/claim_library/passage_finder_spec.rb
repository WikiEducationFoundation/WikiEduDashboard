# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_library/passage_finder"

describe ClaimLibrary::PassageFinder do
  let(:source_text) do
    [
      'Surrogacy has been debated in many countries over several decades of practice.',
      'Following a High Court decision allowing commercial surrogacy in 2002, the market ' \
      'grew steadily. The Confederation of Indian Industry predicts US$2.3 billion annually.',
      'In November 2015, all medical visas related to surrogacy services were suspended.',
      'Short line.'
    ].join("\n\n")
  end
  let(:finder) { described_class.new(source_text, limit: 2) }

  it 'ranks the paragraph sharing the claim\'s numbers and names first' do
    claim = 'A 2002 court decision was read as legalising commercial surrogacy.'
    passages = finder.passages_for(claim)
    expect(passages.first).to start_with('Following a High Court decision')
  end

  it 'returns nothing when no paragraph resembles the claim' do
    expect(finder.passages_for('Penguins moult once a year.')).to be_empty
  end

  it 'never returns more than its limit' do
    expect(finder.passages_for('surrogacy decision market visas').size).to be <= 2
  end

  it 'ignores lines too short to be a passage' do
    expect(finder.passages_for('Short line.')).to be_empty
  end
end
