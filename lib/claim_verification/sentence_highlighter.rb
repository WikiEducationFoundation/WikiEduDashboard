# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/prose_index"

module ClaimVerification
  # Wraps a cited claim's sentence — the prose the citation is attached to, not
  # just the [n] marker — in a `<span class="cv-claim">` carrying the click data,
  # so the whole claim can be highlighted and selected in the ArticleViewer.
  #
  # The sentence is located by finding its text in the paragraph's prose (see
  # ProseIndex) and wrapping exactly that character range. It is deliberately NOT
  # located by walking back from the citation marker: a citation can sit
  # mid-sentence ("...informetrics[1], particularly for..."), and a named source
  # reused across an article puts the same marker on many different sentences, so
  # the marker says nothing reliable about where its sentence starts or ends.
  #
  # Returns false (wrapping nothing) when the sentence isn't in this paragraph or
  # is already inside another claim's span, so the caller can move on or fall
  # back to tagging the marker.
  class SentenceHighlighter
    def initialize(paragraph:, sentence:, data:)
      @paragraph = paragraph
      @sentence = sentence.to_s.gsub(/\s+/, ' ').strip
      @data = data
    end

    def wrap
      index = ProseIndex.new(@paragraph)
      range = index.range_of(@sentence)
      return false if range.nil?
      head, tail = split_out_range(index, *range)
      return false if head.nil? || already_claimed?(head)
      wrap_nodes(head, tail)
      true
    end

    private

    # Splits the boundary text nodes so the sentence occupies whole nodes,
    # returning its first and last. The end is split before the start so the
    # start's offset is still valid when both fall in the same text node — and in
    # that case the sentence ends up wholly within the head, so splitting the
    # start has moved the end into it too.
    def split_out_range(index, start, finish)
      start_node, start_offset = index.boundary_at(start)
      end_node, end_offset = index.boundary_at(finish - 1)
      return [nil, nil] if start_node.nil? || end_node.nil?
      one_node = start_node.equal?(end_node)
      tail = split_at(end_node, end_offset + 1).first
      head = split_at(start_node, start_offset).last
      [head, one_node ? head : tail]
    end

    # Splits `node` at `offset` into [before, after], either of which may be the
    # node itself when the offset is at one of its ends.
    def split_at(node, offset)
      return [nil, node] if offset <= 0
      return [node, nil] if offset >= node.content.length
      after = Nokogiri::XML::Text.new(node.content[offset..], node.document)
      node.add_next_sibling(after)
      node.content = node.content[0...offset]
      [node, after]
    end

    # A sentence normally runs through text and whole inline elements of one
    # parent. When its ends sit at different depths (it starts inside an <i>, say)
    # we wrap the widest siblings of their common ancestor that contain them,
    # which can take in a little adjacent text — still this sentence's region,
    # and far better than the marker-relative guess this replaces.
    def wrap_nodes(head, tail)
      ancestor = common_parent(head, tail)
      first = child_of(ancestor, head)
      last = child_of(ancestor, tail)
      # role=button + tabindex make the highlighted claim a real, focusable
      # control so it can be reached and activated by keyboard / screen reader;
      # the wrapped sentence text is the control's accessible name.
      span = ancestor.document.create_element('span', class: 'cv-claim',
                                              role: 'button', tabindex: '0')
      @data.each { |key, value| span[key] = value if value }
      first.add_previous_sibling(span)
      siblings_through(first, last).each { |node| span.add_child(node) }
    end

    # The nearest element containing both ends as (possibly indirect) children.
    # Searched from the head's ancestors rather than the head itself so that a
    # sentence sitting in a single text node yields that node's parent.
    def common_parent(head, tail)
      tail_line = [tail, *tail.ancestors]
      head.ancestors.find { |node| tail_line.any? { |other| other.equal?(node) } }
    end

    def child_of(ancestor, node)
      node = node.parent until node.parent.nil? || node.parent.equal?(ancestor)
      node
    end

    def siblings_through(first, last)
      nodes = [first]
      nodes << nodes.last.next_sibling while !nodes.last.equal?(last) && nodes.last.next_sibling
      nodes
    end

    # Another claim's span already covers this text — don't nest one inside the
    # other, which would stack their highlights into an ever-darker shade.
    def already_claimed?(node)
      [node, *node.ancestors].any? do |candidate|
        candidate.element? && candidate['class'].to_s.split.include?('cv-claim')
      end
    end
  end
end
