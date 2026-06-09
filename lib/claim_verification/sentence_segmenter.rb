# frozen_string_literal: true

module ClaimVerification
  # Splits a paragraph of MediaWiki parser output into sentences, with
  # the <sup class="reference"> markers that trail each sentence
  # resolved to reference-list ids.
  #
  # Approach: replace each reference sup with an inline marker token,
  # take the plain text, then scan for sentence-shaped chunks where a
  # sentence ends with terminal punctuation plus any reference markers
  # that immediately follow it.
  class SentenceSegmenter
    # Bracket characters that are vanishingly unlikely in article prose.
    MARKER_OPEN = '⦗'
    MARKER_CLOSE = '⦘'
    MARKER_RE = /#{MARKER_OPEN}([^#{MARKER_CLOSE}]+)#{MARKER_CLOSE}/
    # No capture groups here: String#scan must return whole matches.
    SENTENCE_RE = /.*?[.!?]+['"”’)]*(?:\s*#{MARKER_OPEN}[^#{MARKER_CLOSE}]+#{MARKER_CLOSE})*/

    def initialize(paragraph_node)
      @paragraph_node = paragraph_node
    end

    # Returns an array of { sentence:, ref_ids: } hashes.
    def segments
      chunks(text_with_markers).filter_map do |chunk|
        sentence = chunk.gsub(MARKER_RE, '').strip
        next if sentence.empty?
        { sentence:, ref_ids: chunk.scan(MARKER_RE).flatten }
      end
    end

    private

    def text_with_markers
      paragraph = @paragraph_node.dup
      paragraph.css('sup.reference').each do |sup|
        note_id = note_id_for(sup)
        sup.replace(note_id ? "#{MARKER_OPEN}#{note_id}#{MARKER_CLOSE}" : '')
      end
      # Normalized whitespace keeps the sentence scan contiguous, so the
      # post-sentences remainder can be located by length.
      paragraph.text.gsub(/\s+/, ' ')
    end

    # The sup's link points at the reference-list entry:
    # <sup class="reference"><a href="#cite_note-Smith-1">…</a></sup>
    def note_id_for(sup)
      href = sup.at_css('a')&.[]('href')
      return unless href&.start_with?('#cite_note')
      href.delete_prefix('#')
    end

    # Splits text into sentence chunks; any trailing text without
    # terminal punctuation becomes a final chunk.
    def chunks(text)
      sentence_chunks = text.scan(SENTENCE_RE)
      remainder = text[sentence_chunks.sum(&:length)..]
      sentence_chunks << remainder unless remainder.nil? || remainder.strip.empty?
      sentence_chunks
    end
  end
end
