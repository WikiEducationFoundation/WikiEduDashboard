# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/sentence_segmenter"

describe ClaimVerification::SentenceSegmenter do
  # Build a paragraph node from an HTML snippet and segment it.
  def segments(inner_html)
    doc = Nokogiri::HTML.fragment("<p>#{inner_html}</p>")
    described_class.new(doc.at_css('p')).segments
  end

  # A reference sup like MediaWiki emits, pointing at its reference-list entry.
  def ref(note_id)
    %(<sup class="reference"><a href="##{note_id}">[x]</a></sup>)
  end

  describe 'basic segmentation' do
    it 'pairs a sentence with the reference that trails it' do
      result = segments("The site opened to the public in 1990.#{ref('cite_note-1')}")
      expect(result).to eq([{ sentence: 'The site opened to the public in 1990.',
                               ref_ids: ['cite_note-1'] }])
    end

    it 'splits multiple sentences and attaches each ones own reference' do
      result = segments("First fact.#{ref('cite_note-1')} Second fact.#{ref('cite_note-2')}")
      expect(result).to eq([
                             { sentence: 'First fact.', ref_ids: ['cite_note-1'] },
                             { sentence: 'Second fact.', ref_ids: ['cite_note-2'] }
                           ])
    end

    it 'attaches every reference that immediately follows a sentence' do
      result = segments("A well-cited fact.#{ref('cite_note-1')}#{ref('cite_note-2')}")
      expect(result).to eq([{ sentence: 'A well-cited fact.',
                              ref_ids: %w[cite_note-1 cite_note-2] }])
    end

    it 'keeps a reference that sits mid-sentence with that sentence' do
      result = segments("The study,#{ref('cite_note-1')} which was large, found gains.")
      expect(result).to eq([{ sentence: 'The study, which was large, found gains.',
                              ref_ids: ['cite_note-1'] }])
    end

    it 'ignores a reference sup whose link is not a reference-list entry' do
      result = segments('A plain sentence.<sup class="reference"><a href="#section">x</a></sup>')
      expect(result).to eq([{ sentence: 'A plain sentence.', ref_ids: [] }])
    end
  end

  # The whole reason for using PragmaticSegmenter: a period inside an
  # abbreviation, initial, acronym, or decimal must NOT end the sentence, so the
  # cited claim keeps its full text instead of being truncated to a fragment.
  describe 'does not split on internal periods' do
    it 'keeps a decimal number intact' do
      result = segments('The population grew from 2.5 billion in 1950 to 8 billion ' \
                        "today.#{ref('cite_note-1')}")
      expect(result).to eq([{ sentence: 'The population grew from 2.5 billion in 1950 ' \
                                         'to 8 billion today.', ref_ids: ['cite_note-1'] }])
    end

    it 'keeps an acronym intact' do
      result = segments("He lived in the U.S. for a decade.#{ref('cite_note-1')}")
      expect(result).to eq([{ sentence: 'He lived in the U.S. for a decade.',
                              ref_ids: ['cite_note-1'] }])
    end

    it 'keeps a middle initial intact' do
      result = segments("George W. Bush served two terms.#{ref('cite_note-1')}")
      expect(result).to eq([{ sentence: 'George W. Bush served two terms.',
                              ref_ids: ['cite_note-1'] }])
    end

    it 'keeps title abbreviations intact' do
      result = segments("She met Dr. Smith at St. Mary's hospital.#{ref('cite_note-1')}")
      expect(result).to eq([{ sentence: "She met Dr. Smith at St. Mary's hospital.",
                              ref_ids: ['cite_note-1'] }])
    end

    it 'keeps a latin abbreviation intact' do
      result = segments("Many places, e.g. cafes, now qualify.#{ref('cite_note-1')}")
      expect(result).to eq([{ sentence: 'Many places, e.g. cafes, now qualify.',
                              ref_ids: ['cite_note-1'] }])
    end
  end

  # Documents a residual limitation, not desired behavior: an abbreviation at a
  # true sentence end, immediately before a capitalized next sentence, is
  # ambiguous, and the segmenter treats it as non-terminal — merging the two
  # sentences. Both citations still attach to the merged sentence.
  describe 'known residual ambiguity' do
    it 'merges a sentence ending in an acronym before a capitalized sentence' do
      result = segments("He moved to the U.S.#{ref('cite_note-1')} " \
                        "He stayed for years.#{ref('cite_note-2')}")
      expect(result).to eq([{ sentence: 'He moved to the U.S. He stayed for years.',
                              ref_ids: %w[cite_note-1 cite_note-2] }])
    end
  end
end
