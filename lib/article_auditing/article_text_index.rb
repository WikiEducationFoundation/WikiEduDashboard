# frozen_string_literal: true

module ArticleAuditing
  # The text of a rendered article, normalized the way QuoteValidator compares
  # quotes (case, curly quotes and whitespace runs folded), with a map from
  # each character back to the DOM text node and offset it came from. That map
  # is what lets FindingAnchors turn a matched quote into highlighted nodes.
  #
  # Citation markers ([1]) and edit-section links contribute no text, since
  # findings quote the prose without them. Positions are only valid until the
  # document changes.
  class ArticleTextIndex
    SKIPPED = %w[style script].freeze
    # Elements that start a new line when rendered, so that text either side
    # of them doesn't run together.
    BLOCKS = %w[p div li dd dt td th tr br h1 h2 h3 h4 h5 h6 ul ol dl table blockquote
                figure figcaption].freeze
    FOLDED = { '“' => '"', '”' => '"', '‘' => "'", '’' => "'" }.freeze

    attr_reader :text

    def self.normalize(string)
      # [[:space:]] rather than \s, so that non-breaking spaces count.
      string.to_s.tr(FOLDED.keys.join, FOLDED.values.join)
            .gsub(/[[:space:]]+/, ' ').downcase.strip
    end

    def initialize(root)
      @text = +''
      @positions = [] # parallel to @text: [text node, offset] for each character
      @headings = [] # [element, position where its text starts]
      absorb(root)
    end

    # Character ranges [start, end) of +needle+ (already normalized), with
    # those inside +section+ first.
    def ranges_of(needle, section: nil)
      return [] if needle.empty?
      starts = []
      start = @text.index(needle)
      while start
        starts << start
        start = @text.index(needle, start + 1)
      end
      within = section_span(section)
      starts.sort_by { |s| within&.cover?(s) ? 0 : 1 }.map { |s| [s, s + needle.length] }
    end

    # { text node => [[first offset, last offset]] } covered by the range.
    def node_spans(start, finish)
      @positions[start...finish].group_by(&:first).transform_values do |positions|
        offsets = positions.map(&:last)
        [offsets.min, offsets.max]
      end
    end

    # The heading element whose text matches +section+, if any.
    def heading(section)
      name = self.class.normalize(section)
      @headings.find { |element, _| self.class.normalize(element.text) == name }&.first
    end

    private

    def absorb(node)
      node.children.each do |child|
        next if skipped?(child)
        @headings << [child, @text.length] if heading?(child)
        separate if child.element? && BLOCKS.include?(child.name)
        child.text? ? absorb_text(child) : absorb(child)
      end
    end

    def absorb_text(node)
      node.content.each_char.with_index do |char, offset|
        if char.match?(/[[:space:]]/)
          next if @text.empty? || @text.end_with?(' ')
          add(' ', node, offset)
        else
          # Some characters lowercase to two, which both map to this one.
          (FOLDED[char] || char.downcase).each_char { |folded| add(folded, node, offset) }
        end
      end
    end

    # A space between blocks, mapped to the last character before it.
    def separate
      return if @text.empty? || @text.end_with?(' ')
      @text << ' '
      @positions << @positions.last
    end

    def add(char, node, offset)
      @text << char
      @positions << [node, offset]
    end

    # The [start, end) text positions from +section+'s heading to the next.
    def section_span(section)
      return if section.blank?
      index = @headings.index { |element, _| element.equal?(heading(section)) }
      return if index.nil?
      finish = @headings[index + 1]&.last || @text.length
      @headings[index].last...finish
    end

    def heading?(node)
      node.element? && node.name.match?(/\Ah[1-6]\z/)
    end

    def skipped?(node)
      return false unless node.element?
      return true if SKIPPED.include?(node.name)
      classes = node['class'].to_s.split
      (node.name == 'sup' && classes.include?('reference')) || classes.include?('mw-editsection')
    end
  end
end
