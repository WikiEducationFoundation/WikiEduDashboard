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

  describe 'sentences that end cleanly' do
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

    it 'keeps a trailing fragment that has no terminal punctuation' do
      result = segments("A fact.#{ref('cite_note-1')} and then more text")
      expect(result).to eq([
                             { sentence: 'A fact.', ref_ids: ['cite_note-1'] },
                             { sentence: 'and then more text', ref_ids: [] }
                           ])
    end

    it 'drops a reference sup whose link is not a reference-list entry' do
      result = segments('A plain sentence.<sup class="reference"><a href="#section">x</a></sup>')
      expect(result).to eq([{ sentence: 'A plain sentence.', ref_ids: [] }])
    end
  end

  # CHARACTERIZATION TESTS — these document the over-splitting flagged in the
  # PR #6921 review, NOT desired behavior. SENTENCE_RE treats any '.'/'!'/'?' as a
  # sentence end, so a period inside an abbreviation, initial, or decimal ends the
  # "sentence" early and the citation binds to the trailing fragment — the stored
  # claim loses everything before that last internal period. When the segmenter is
  # fixed, these expectations should flip to the full sentence noted in each case.
  describe 'over-splitting on internal periods (known limitation, documents the bug)' do
    it 'truncates a claim with a decimal to the post-decimal fragment' do
      # Desired: 'The population grew from 2.5 billion in 1950 to 8 billion today.'
      result = segments("The population grew from 2.5 billion in 1950 to 8 billion " \
                        "today.#{ref('cite_note-1')}")
      cited = result.find { |s| s[:ref_ids].any? }
      expect(cited[:sentence]).to eq('5 billion in 1950 to 8 billion today.')
    end

    it 'truncates a claim that ends after an abbreviation' do
      # Desired: 'He lived in the U.S. for a decade.'
      result = segments("He lived in the U.S. for a decade.#{ref('cite_note-1')}")
      cited = result.find { |s| s[:ref_ids].any? }
      expect(cited[:sentence]).to eq('for a decade.')
    end

    it 'truncates a claim that contains a middle initial' do
      # Desired: 'George W. Bush served two terms.'
      result = segments("George W. Bush served two terms.#{ref('cite_note-1')}")
      cited = result.find { |s| s[:ref_ids].any? }
      expect(cited[:sentence]).to eq('Bush served two terms.')
    end
  end
end
