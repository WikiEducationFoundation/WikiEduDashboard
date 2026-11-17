# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/finding"
require_dependency "#{Rails.root}/lib/article_auditing/article_text_index"
require_dependency "#{Rails.root}/lib/article_auditing/wikitext_quote"

module ArticleAuditing
  # Places an audit's findings on the rendered article, for the report's
  # side-by-side view. Each finding is anchored, in order of preference:
  # - 'text': its quote, found in the rendered text (in its section, if the
  #   quote occurs more than once)
  # - 'reference' or 'text': for a quote of wikitext, the citation it comes
  #   from in the reference list, or the quote with its markup stripped
  #   (see WikitextQuote)
  # - 'section': the heading of its section, or the top of the article for
  #   the lead
  # Findings that fit none of these (most findings about the whole article)
  # get no anchor.
  #
  # Anchored text is wrapped in <mark class="aa-mark ..." data-findings="ids">,
  # colored by the most severe finding on it; overlapping findings share marks.
  # A section anchor puts the ids on the heading's data-section-findings.
  # Relative links are pointed at the wiki, and edit-section links removed.
  class FindingAnchors
    LEAD = 'lead'

    attr_reader :anchors

    # +findings+ are Finding hashes, each with a unique 'id'.
    def initialize(html:, wikitext:, base_url:, findings:)
      @doc = Nokogiri::HTML.fragment(html.to_s)
      @wikitext = wikitext
      @base_url = base_url
      @findings = findings
      @anchors = {}
      @spans = Hash.new { |hash, node| hash[node] = [] } # text node => [[from, to, finding]]
      anchor_all
      tidy_links
    end

    def html
      @doc.to_html
    end

    private

    def anchor_all
      @index = ArticleTextIndex.new(@doc)
      @findings.each do |finding|
        kind = anchor_quote(finding) || anchor_section(finding)
        @anchors[finding['id']] = kind if kind
      end
      @spans.each { |node, spans| mark(node, spans) }
    end

    def anchor_quote(finding)
      quote = finding.dig('location', 'quote')
      return if quote.blank?
      section = finding.dig('location', 'section')
      needle = ArticleTextIndex.normalize(quote).delete_prefix('...').delete_suffix('...').strip
      return 'text' if anchor_text(needle, section, finding)
      WikitextQuote.new(quote, @wikitext).candidates.each do |kind, text|
        return kind if anchor_text(text, section, finding)
      end
      nil
    end

    def anchor_text(needle, section, finding)
      start, finish = @index.ranges_of(needle, section:).first
      return false if start.nil?
      @index.node_spans(start, finish).each do |node, (from, to)|
        @spans[node] << [from, to + 1, finding]
      end
      true
    end

    def anchor_section(finding)
      section = finding.dig('location', 'section')
      return if section.blank?
      element = section.strip.casecmp?(LEAD) ? lead_element : @index.heading(section)
      return if element.nil?
      element['data-section-findings'] = [element['data-section-findings'], finding['id']]
                                         .compact.join(' ')
      'section'
    end

    def lead_element
      root = @doc.at_css('.mw-parser-output') || @doc
      root.element_children.find { |child| child.name == 'p' && child.text.strip.present? }
    end

    # Splits +node+ at every span boundary and wraps the covered pieces.
    def mark(node, spans)
      cuts = ([0, node.content.length] + spans.flat_map { |from, to, _| [from, to] }).uniq.sort
      pieces = cuts.each_cons(2).map do |from, to|
        covering = spans.select { |start, finish, _| start <= from && to <= finish }.map(&:last)
        piece(node.content[from...to], covering)
      end
      pieces.each { |piece| node.add_previous_sibling(piece) }
      node.remove
    end

    def piece(text, findings)
      return Nokogiri::XML::Text.new(text, @doc.document) if findings.empty?
      severity = findings.map { |finding| finding['severity'] }
                         .min_by { |name| Finding::SEVERITIES.index(name) || Finding::SEVERITIES.size }
      mark = @doc.document.create_element('mark', text, class: "aa-mark aa-mark--#{severity}")
      mark['data-findings'] = findings.map { |finding| finding['id'] }.uniq.join(' ')
      mark
    end

    def tidy_links
      @doc.css('.mw-editsection').each(&:remove)
      @doc.css('a[href]').each do |link|
        next if link['href'].start_with?('#')
        link['href'] = "#{@base_url}#{link['href']}" if link['href'].match?(%r{\A/[^/]})
        link['target'] = '_blank'
        link['rel'] = 'noopener noreferrer'
      end
    end
  end
end
