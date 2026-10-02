# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/sentence_highlighter"

describe ClaimVerification::SentenceHighlighter do
  def wrap(html, sentence:, data: { 'data-claim-id' => '7' })
    doc = Nokogiri::HTML.fragment(html)
    result = described_class.new(paragraph: doc.at_css('p'), sentence:, data:).wrap
    [result, doc]
  end

  def marker(ref)
    %(<sup class="reference"><a href="##{ref}">[1]</a></sup>)
  end

  it 'wraps the cited sentence in a cv-claim span carrying the data' do
    result, doc = wrap("<p>The otter dives.#{marker('c')}</p>", sentence: 'The otter dives.')
    expect(result).to be true
    span = doc.at_css('span.cv-claim')
    expect(span['data-claim-id']).to eq('7')
    expect(span.text).to include('The otter dives.')
  end

  it 'makes the span a focusable control for keyboard and screen-reader users' do
    _result, doc = wrap("<p>The otter dives.#{marker('c')}</p>", sentence: 'The otter dives.')
    span = doc.at_css('span.cv-claim')
    expect(span['role']).to eq('button')
    expect(span['tabindex']).to eq('0')
  end

  # The sentence is found by its text, so where the citation sits within it makes
  # no difference — this is what the marker-relative approach could not do.
  it 'wraps a sentence whose citation sits in the middle of it' do
    result, doc = wrap(
      "<p>The otter dives#{marker('c')}, then surfaces.#{marker('d')}</p>",
      sentence: 'The otter dives, then surfaces.'
    )
    expect(result).to be true
    expect(doc.at_css('span.cv-claim').text).to include('The otter dives', 'then surfaces.')
  end

  # The segmenter's sentence keeps the full stop that follows the citation
  # ("physics[3]."), so the highlight has to reach past the marker to cover it.
  it 'includes sentence-final punctuation that follows the citation' do
    result, doc = wrap(
      "<p>Brookes studied physics#{marker('c')}. Then he left.</p>",
      sentence: 'Brookes studied physics.'
    )
    expect(result).to be true
    span = doc.at_css('span.cv-claim')
    expect(span.text).to end_with('.')
    expect(span.text).not_to include('Then he left')
  end

  # A source reused across an article puts the same marker on several sentences.
  # The highlight must follow the sentence it was given, not the nearest marker.
  it 'wraps the sentence it was given when the same source cites several' do
    result, doc = wrap(
      "<p>First claim.#{marker('shared')} Second claim.#{marker('shared')}</p>",
      sentence: 'Second claim.'
    )
    expect(result).to be true
    span = doc.at_css('span.cv-claim')
    expect(span.text).to include('Second claim.')
    expect(span.text).not_to include('First claim')
  end

  it 'wraps a sentence that runs through inline markup' do
    result, doc = wrap(
      "<p>The <i>Enhydra lutris</i> dives deep.#{marker('c')}</p>",
      sentence: 'The Enhydra lutris dives deep.'
    )
    expect(result).to be true
    span = doc.at_css('span.cv-claim')
    expect(span.at_css('i')).to be_present
    expect(span.text).to include('The Enhydra lutris dives deep.')
  end

  it 'matches regardless of how whitespace is broken up in the markup' do
    result, doc = wrap(
      "<p>The otter\n   dives.#{marker('c')}</p>", sentence: 'The otter dives.'
    )
    expect(result).to be true
    expect(doc.at_css('span.cv-claim')).to be_present
  end

  it 'leaves surrounding prose outside the span' do
    _result, doc = wrap(
      "<p>Before it. The otter dives.#{marker('c')} After it.</p>",
      sentence: 'The otter dives.'
    )
    span = doc.at_css('span.cv-claim')
    expect(span.text).not_to include('Before it', 'After it')
  end

  it 'wraps nothing when the sentence is not in this paragraph' do
    result, doc = wrap("<p>The otter dives.#{marker('c')}</p>", sentence: 'The otter sleeps.')
    expect(result).to be false
    expect(doc.at_css('.cv-claim')).to be_nil
  end

  # Nesting one claim's span inside another stacks their highlights into an
  # ever-darker shade, so a sentence already covered is refused.
  it 'refuses a sentence already inside another claim span' do
    result, doc = wrap(
      '<p><span class="cv-claim" data-claim-id="1">The otter dives.</span></p>',
      sentence: 'The otter dives.'
    )
    expect(result).to be false
    expect(doc.css('.cv-claim .cv-claim')).to be_empty
  end
end
