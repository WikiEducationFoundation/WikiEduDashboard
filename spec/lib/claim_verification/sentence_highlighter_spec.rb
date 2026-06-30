# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/sentence_highlighter"

describe ClaimVerification::SentenceHighlighter do
  def wrap(html, sentence:, data: {})
    doc = Nokogiri::HTML.fragment(html)
    marker = doc.at_css('sup.reference')
    result = described_class.new(marker:, sentence:, data:).wrap
    [result, doc]
  end

  it 'wraps the cited sentence in a cv-claim span carrying the data' do
    result, doc = wrap(
      '<p>The otter dives.<sup class="reference"><a href="#c">[1]</a></sup></p>',
      sentence: 'The otter dives.', data: { 'data-claim-id' => '7' }
    )
    expect(result).to be true
    span = doc.at_css('span.cv-claim')
    expect(span['data-claim-id']).to eq('7')
    expect(span.text).to include('The otter dives.')
  end

  # Without the boundary stop, the backward walk falls a character short on this
  # claim's own prose, reaches the previous claim's span, and (unable to split an
  # element) swallows it whole — nesting the spans, which is what stacked the
  # highlight into a darker shade.
  it 'stops at a previous claim span instead of nesting it' do
    result, doc = wrap(
      '<p><span class="cv-claim" data-claim-id="1">one</span> two' \
      '<sup class="reference"><a href="#c">[1]</a></sup></p>',
      sentence: 'abcd', data: { 'data-claim-id' => '2' }
    )
    expect(result).to be true
    expect(doc.css('.cv-claim').size).to eq(2)
    expect(doc.css('.cv-claim .cv-claim')).to be_empty
  end
end
