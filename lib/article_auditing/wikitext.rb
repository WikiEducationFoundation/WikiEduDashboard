# frozen_string_literal: true

module ArticleAuditing
  # Lightweight, read-only structural view of a page's wikitext for
  # deterministic checks. Not a full parser: it finds section headings and can
  # blank out markup (templates, refs, comments, tables) that prose-level
  # checks should ignore.
  class Wikitext
    Section = Data.define(:level, :title, :body, :line)

    HEADING = /^(={2,6})[ \t]*(.+?)[ \t]*\1[ \t]*$/
    COMMENT = /<!--.*?-->/m
    # <ref name="x" /> and <ref ...>...</ref>
    SELF_CLOSING_REF = %r{<ref\b[^>]*/>}i
    REF = %r{<ref\b(?:[^>]*[^/])?>.*?</ref\s*>}im

    attr_reader :text

    def initialize(text)
      @text = text.to_s
    end

    # Sections in order. Text before the first heading is the lead, with
    # level 1 and title nil.
    def sections
      @sections ||= split_sections
    end

    def lead
      sections.first
    end

    def headings
      sections.drop(1)
    end

    def ref_tags?
      text.match?(/<ref\b/i)
    end

    def ref_count
      text.scan(/<ref\b/i).size
    end

    # Text with comments, refs, templates and tables replaced by spaces of the
    # same length, so match offsets still line up with the original text.
    def masked
      @masked ||= mask_markup(text)
    end

    # Text with comments removed but refs and templates intact.
    def without_comments
      @without_comments ||= text.gsub(COMMENT) { |m| ' ' * m.length }
    end

    private

    def split_sections
      result = []
      current = { level: 1, title: nil, line: 1, lines: [] }
      text.each_line.with_index(1) do |line, number|
        match = line.match(HEADING)
        if match
          result << build_section(current)
          current = { level: match[1].length, title: match[2], line: number, lines: [] }
        else
          current[:lines] << line
        end
      end
      result << build_section(current)
    end

    def build_section(attrs)
      Section.new(level: attrs[:level], title: attrs[:title], body: attrs[:lines].join,
                  line: attrs[:line])
    end

    def mask_markup(source)
      masked = source.gsub(COMMENT) { |m| ' ' * m.length }
      masked = masked.gsub(REF) { |m| ' ' * m.length }
      masked = masked.gsub(SELF_CLOSING_REF) { |m| ' ' * m.length }
      mask_nested(masked, '{{', '}}')
      mask_nested(masked, '{|', '|}')
      masked
    end

    # Blanks out balanced, possibly nested, open...close spans in place.
    def mask_nested(source, open, close)
      outermost_spans(source, open, close).each do |span|
        source[span] = ' ' * span.size
      end
      source
    end

    # Ranges of the outermost balanced open...close spans in +source+.
    def outermost_spans(source, open, close)
      depth = 0
      start = nil
      delimiters = /#{Regexp.escape(open)}|#{Regexp.escape(close)}/
      source.to_enum(:scan, delimiters).filter_map do
        match = Regexp.last_match
        if match[0] == open
          start = match.begin(0) if depth.zero?
          depth += 1
          nil
        elsif depth.positive?
          depth -= 1
          (start...match.end(0)) if depth.zero?
        end
      end
    end
  end
end
