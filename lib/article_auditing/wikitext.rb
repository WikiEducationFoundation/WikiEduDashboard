# frozen_string_literal: true

module ArticleAuditing
  # Lightweight, read-only structural view of a page's wikitext for
  # deterministic checks. Not a full parser: it finds section headings and can
  # blank out markup (templates, refs, comments, tables) that prose-level
  # checks should ignore.
  class Wikitext
    # offset is the index in #text where the section's body starts.
    Section = Data.define(:level, :title, :body, :line, :offset)

    HEADING = /^(={2,6})[ \t]*(.+?)[ \t]*\1[ \t]*$/
    COMMENT = /<!--.*?-->/m
    # <ref name="x" /> and <ref ...>...</ref>
    SELF_CLOSING_REF = %r{<ref\b[^>]*/>}i
    REF = %r{<ref\b(?:[^>]*[^/])?>.*?</ref\s*>}im
    # Templates that generate footnotes without a literal <ref> tag.
    FOOTNOTE_TEMPLATE = /\{\{\s*(?:sfnm?|sfnp|r)\s*\|/i

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

    # The section containing character +index+ of #text.
    def section_at(index)
      sections.reverse.find { |section| section.offset <= index } || lead
    end

    # The masked body text of +section+.
    def masked_body(section)
      masked[section.offset, section.body.length]
    end

    def headings
      sections.drop(1)
    end

    def ref_tags?
      text.match?(/<ref\b/i)
    end

    # Whether the page has any inline citations: <ref> tags, or footnote
    # templates such as {{sfn}} and {{r}} that produce them.
    def inline_citations?
      without_comments.match?(/<ref\b/i) || without_comments.match?(FOOTNOTE_TEMPLATE)
    end

    def ref_count
      text.scan(/<ref\b/i).size
    end

    # Text with comments, refs, templates and tables replaced by spaces of the
    # same length, so match offsets still line up with the original text.
    def masked
      @masked ||= mask_markup(text)
    end

    # Top-level templates (not nested in another template) whose name matches
    # +name_pattern+, as [offset, template_text] pairs. Templates inside refs
    # count as top level.
    def templates(name_pattern)
      outermost_spans(without_comments, '{{', '}}').filter_map do |span|
        template = without_comments[span]
        name = template[2..].split(/[|}]/, 2).first.to_s.strip
        [span.begin, template] if name.match?(name_pattern)
      end
    end

    # Text with comments removed but refs and templates intact. Comments are
    # blanked except for their line breaks, so offsets and lines both still
    # line up with #text.
    def without_comments
      @without_comments ||= text.gsub(COMMENT) { |m| m.gsub(/[^\n]/, ' ') }
    end

    private

    # Headings are matched with comments blanked out, as MediaWiki does: a
    # commented-out heading isn't one, and a comment after a heading doesn't
    # stop it being one.
    def split_sections
      result = []
      current = { level: 1, title: nil, line: 1, lines: [], offset: 0 }
      position = 0
      text.each_line.zip(without_comments.each_line).each.with_index(1) do |(line, bare), number|
        position += line.length
        match = bare.match(HEADING)
        if match
          result << build_section(current)
          current = { level: match[1].length, title: match[2], line: number, lines: [],
                      offset: position }
        else
          current[:lines] << line
        end
      end
      result << build_section(current)
    end

    def build_section(attrs)
      Section.new(level: attrs[:level], title: attrs[:title], body: attrs[:lines].join,
                  line: attrs[:line], offset: attrs[:offset])
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
