# frozen_string_literal: true

module ClaimVerification
  # A block element's prose as the sentence segmenter saw it, plus the means to
  # get back from a position in that text to the DOM node it came from.
  #
  # `text` is built the same way SentenceSegmenter builds its input, so a stored
  # claim sentence can be found in it by plain string search:
  # - reference markers (`<sup class="reference">`) contribute nothing, since the
  #   segmenter replaced them with tokens and then stripped the tokens
  # - runs of whitespace collapse to one space
  #
  # `boundary_at` returns the [text node, offset] a given character came from,
  # which is what lets a matched sentence be turned back into a node range. The
  # positions are only valid until the document is mutated, so build an index,
  # use it, and rebuild it if the DOM changes underneath.
  class ProseIndex
    attr_reader :text

    def initialize(root)
      @text = +''
      # Parallel to @text: the [node, offset] each character was taken from.
      @positions = []
      absorb(root)
    end

    # The [start, end) character range of `sentence` in this prose, or nil when
    # it isn't here. `sentence` must already be whitespace-normalized.
    def range_of(sentence)
      start = @text.index(sentence)
      start && [start, start + sentence.length]
    end

    # The [node, offset] the character at `position` came from.
    def boundary_at(position)
      @positions[position]
    end

    private

    def absorb(node)
      node.children.each do |child|
        next if reference_marker?(child)
        child.text? ? absorb_text(child) : absorb(child)
      end
    end

    # Copies `node`'s characters into the prose, collapsing whitespace runs into
    # a single space — and recording, for each character kept, where it came from.
    # A collapsed run is represented by its first character, so a range boundary
    # landing on whitespace still maps to a real position in the document.
    def absorb_text(node)
      node.content.each_char.with_index do |char, offset|
        if char.match?(/\s/)
          next if @text.end_with?(' ') || @text.empty?
          @text << ' '
        else
          @text << char
        end
        @positions << [node, offset]
      end
    end

    def reference_marker?(node)
      node.element? && node.name == 'sup' && node['class'].to_s.include?('reference')
    end
  end
end
