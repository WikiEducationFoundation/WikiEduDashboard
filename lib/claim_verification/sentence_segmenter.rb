# frozen_string_literal: true

require 'pragmatic_segmenter'

module ClaimVerification
  # Splits a paragraph of MediaWiki parser output into sentences, with the
  # <sup class="reference"> markers that trail each sentence resolved to
  # reference-list ids.
  #
  # Approach: replace each reference sup with an inline marker token, then run
  # PragmaticSegmenter over the text. PragmaticSegmenter is a corpus-tuned
  # sentence boundary detector, so it keeps abbreviations ("Dr."), initials
  # ("George W."), decimals ("2.5"), and the like from ending a sentence early —
  # the failure mode of a plain "split on .!?" scan.
  #
  # PragmaticSegmenter treats a citation that follows a sentence-final period as
  # the start of the *next* sentence, so a marker that leads a segment is folded
  # back onto the preceding sentence; a marker sitting mid-segment stays with its
  # own sentence. Either way each marker ends up on the sentence whose text it
  # trailed in the source.
  class SentenceSegmenter
    # Bracket characters that are vanishingly unlikely in article prose.
    MARKER_OPEN = '⦗'
    MARKER_CLOSE = '⦘'
    MARKER_RE = /#{MARKER_OPEN}([^#{MARKER_CLOSE}]+)#{MARKER_CLOSE}/
    LEADING_MARKER_RE = /\A#{MARKER_RE}/

    def initialize(paragraph_node)
      @paragraph_node = paragraph_node
    end

    # Returns an array of { sentence:, ref_ids: } hashes.
    def segments
      segment_chunks(text_with_markers).each_with_object([]) do |chunk, sentences|
        fold_chunk(chunk, sentences)
      end
    end

    private

    def segment_chunks(text)
      PragmaticSegmenter::Segmenter.new(text:).segment
    end

    # Fold one segmenter chunk into the running list of sentences. Markers that
    # lead the chunk cite the preceding sentence (PragmaticSegmenter starts the
    # next sentence with a sentence-final citation); the rest is this chunk's
    # sentence and carries any markers within it.
    def fold_chunk(chunk, sentences)
      leading, body = split_leading_markers(chunk)
      sentences.last[:ref_ids].concat(leading) if leading.any? && sentences.any?
      sentence = body.gsub(MARKER_RE, '').strip
      return if sentence.empty?
      ref_ids = body.scan(MARKER_RE).flatten
      ref_ids = leading + ref_ids if sentences.empty?
      sentences << { sentence:, ref_ids: }
    end

    # Peel the reference markers (and surrounding whitespace) off the front of a
    # chunk, returning [leading_ref_ids, remaining_text].
    def split_leading_markers(chunk)
      leading = []
      rest = chunk.lstrip
      while (match = rest.match(LEADING_MARKER_RE))
        leading << match[1]
        rest = rest[match[0].length..].lstrip
      end
      [leading, rest]
    end

    def text_with_markers
      paragraph = @paragraph_node.dup
      paragraph.css('sup.reference').each do |sup|
        note_id = note_id_for(sup)
        sup.replace(note_id ? "#{MARKER_OPEN}#{note_id}#{MARKER_CLOSE}" : '')
      end
      # Normalized whitespace keeps the segmenter's input clean and single-spaced.
      paragraph.text.gsub(/\s+/, ' ')
    end

    # The sup's link points at the reference-list entry:
    # <sup class="reference"><a href="#cite_note-Smith-1">…</a></sup>
    def note_id_for(sup)
      href = sup.at_css('a')&.[]('href')
      return unless href&.start_with?('#cite_note')
      href.delete_prefix('#')
    end
  end
end
