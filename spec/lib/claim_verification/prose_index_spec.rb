# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/prose_index"

# The index's whole job is to present a paragraph's prose the way
# SentenceSegmenter saw it, so a stored claim sentence can be found in it by
# plain string search, and then mapped back to the nodes it came from.
describe ClaimVerification::ProseIndex do
  def index_for(html)
    described_class.new(Nokogiri::HTML.fragment(html).at_css('p'))
  end

  def marker(ref = 'c')
    %(<sup class="reference"><a href="##{ref}">[1]</a></sup>)
  end

  describe '#text' do
    it 'omits reference markers, which the segmenter stripped from its sentences' do
      expect(index_for("<p>The otter dives.#{marker}</p>").text).to eq('The otter dives.')
    end

    it 'omits a marker sitting inside a sentence' do
      index = index_for("<p>The otter dives#{marker}, then surfaces.</p>")
      expect(index.text).to eq('The otter dives, then surfaces.')
    end

    it 'collapses whitespace runs to a single space' do
      expect(index_for("<p>The otter\n\n   dives.</p>").text).to eq('The otter dives.')
    end

    it 'collapses whitespace that spans element boundaries' do
      expect(index_for('<p>The <i>otter </i> dives.</p>').text).to eq('The otter dives.')
    end

    it 'reads through inline markup as one run of prose' do
      expect(index_for('<p>The <i>Enhydra</i> dives.</p>').text).to eq('The Enhydra dives.')
    end

    it 'drops leading whitespace rather than starting the prose with a space' do
      expect(index_for('<p>  The otter dives.</p>').text).to eq('The otter dives.')
    end
  end

  describe '#range_of' do
    it 'locates a sentence within the prose' do
      index = index_for('<p>Before it. The otter dives. After it.</p>')
      start, finish = index.range_of('The otter dives.')
      expect(index.text[start...finish]).to eq('The otter dives.')
    end

    it 'is nil for a sentence that is not there' do
      expect(index_for('<p>The otter dives.</p>').range_of('The otter sleeps.')).to be_nil
    end
  end

  describe '#boundary_at' do
    it 'maps a position back to the node and offset it came from' do
      index = index_for('<p>The otter dives.</p>')
      node, offset = index.boundary_at(index.text.index('otter'))
      expect(node.content[offset..]).to start_with('otter')
    end

    it 'maps across an inline element to the right node' do
      index = index_for('<p>The <i>Enhydra</i> dives.</p>')
      node, offset = index.boundary_at(index.text.index('Enhydra'))
      expect(node.parent.name).to eq('i')
      expect(node.content[offset..]).to start_with('Enhydra')
    end
  end
end
