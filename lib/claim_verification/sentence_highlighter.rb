# frozen_string_literal: true

module ClaimVerification
  # Wraps a cited claim's sentence — the prose the citation marker is attached to,
  # not just the [n] marker — in a <span class="cv-claim"> carrying the click data,
  # so the whole claim can be highlighted and selected in the ArticleViewer.
  #
  # The sentence ends just before the citation marker, so we walk backward over the
  # marker's preceding siblings, accumulating their text until it covers the
  # sentence (compared by non-whitespace character count, which is robust to
  # whitespace differences between the segmenter's text and the DOM), then wrap that
  # node range. The boundary node is split so only the sentence's share is included.
  # Returns false (wrapping nothing) when the sentence can't be located, so the
  # caller can fall back to tagging the marker.
  class SentenceHighlighter
    def initialize(marker:, sentence:, data:)
      @marker = marker
      @sentence = sentence
      @data = data
    end

    def wrap
      nodes = sentence_nodes
      return false if nodes.empty?
      # role=button + tabindex make the highlighted claim a real, focusable
      # control so it can be reached and activated by keyboard / screen reader;
      # the wrapped sentence text is the control's accessible name.
      span = nodes.first.document.create_element('span', class: 'cv-claim',
                                                 role: 'button', tabindex: '0')
      @data.each { |key, value| span[key] = value if value }
      nodes.first.add_previous_sibling(span)
      nodes.each { |node| span.add_child(node) }
      true
    end

    private

    def sentence_nodes
      target = non_ws_count(@sentence)
      return [] if target.zero?
      acc = 0
      collected = []
      node = @marker.previous_sibling
      # Walk back over the sentence's prose, but stop at an already-highlighted
      # claim: a sentence must not extend into a previous claim's span. Without
      # this, when the count falls a little short the walk swallows the whole
      # neighbouring span (it can't be split), nesting the spans and stacking
      # their highlight into an ever-darker shade. The previous claim's span ends
      # exactly where this sentence begins, so the prose gathered up to it is the
      # sentence even if a few characters short of the segmented length.
      while node && acc < target && !already_highlighted?(node)
        prev = node.previous_sibling
        acc += consume(node, collected, target - acc)
        node = prev
      end
      acc >= target || already_highlighted?(node) ? collected : []
    end

    def already_highlighted?(node)
      node&.element? && node['class'].to_s.split.include?('cv-claim')
    end

    # Prepends `node` to the (forward-ordered) sentence run, returning how many
    # non-whitespace characters of the sentence it contributed.
    def consume(node, collected, remaining)
      if reference_marker?(node)
        collected.unshift(node)
        return 0
      end
      count = non_ws_count(node.text)
      if count >= remaining
        collected.unshift(node.text? ? split_keeping_trailing_nonws(node, remaining) : node)
        remaining
      else
        collected.unshift(node)
        count
      end
    end

    # Splits `text_node` so it retains only its trailing `keep` non-whitespace
    # characters (the sentence's share); the rest stays as a preceding sibling.
    def split_keeping_trailing_nonws(text_node, keep)
      text = text_node.content
      return text_node if non_ws_count(text) <= keep
      count = 0
      idx = text.length
      while idx.positive? && count < keep
        idx -= 1
        count += 1 unless text[idx].match?(/\s/)
      end
      text_node.add_previous_sibling(Nokogiri::XML::Text.new(text[0...idx], text_node.document))
      text_node.content = text[idx..]
      text_node
    end

    def reference_marker?(node)
      node.element? && node.name == 'sup' && node['class'].to_s.include?('reference')
    end

    def non_ws_count(string)
      string.to_s.gsub(/\s/, '').length
    end
  end
end
