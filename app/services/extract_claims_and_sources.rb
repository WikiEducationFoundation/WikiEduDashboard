# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"
require_dependency "#{Rails.root}/lib/reference_list_parser"

# Extracts (factual claim, cited source) pairs from a Wikipedia article,
# for use in source verification exercises. Each result pairs the details
# of the cited reference(s) with both the full sentence the citation
# appears in (+sentence+) and the portion of it the citation supports
# (+claim+) — these differ when a sentence has mid-sentence citations,
# e.g. "Some have fallen,[1] and others were hurt.[2]" yields a second
# claim of "and others were hurt." within the full sentence. Pass either
# an article +title+ (the latest revision is used) or a specific
# +mw_rev_id+. When +only_within+ is given — a plain text corpus, such as
# the text added by particular students — only claims whose text appears
# within that corpus are kept.
class ExtractClaimsAndSources
  # Results whose full sentence is shorter than this are dropped.
  MIN_CLAIM_LENGTH = 40

  SENTENCE_BOUNDARY = /(?:(?<=[.!?])|(?<=[.!?]["']))\s+/

  attr_reader :claims, :article_title, :mw_page_id, :mw_rev_id

  def initialize(wiki, title: nil, mw_rev_id: nil, only_within: nil)
    @wiki = wiki
    @title = title
    @mw_rev_id = mw_rev_id
    @only_within = only_within&.squish
    @article_content = WikiApi::ArticleContent.new(@wiki)
    @claims = []
    extract
  end

  private

  def extract
    @mw_rev_id ||= @article_content.latest_revision_id(@title)
    return if @mw_rev_id.nil?
    fetch_revision_html
    return if @rev_html.nil?
    parse_claims
    filter_claims
  end

  def fetch_revision_html
    result = @article_content.revision_html(@mw_rev_id)
    @rev_html = result[:html]
    @article_title = result[:title]
    @mw_page_id = result[:page_id]
  end

  def parse_claims
    doc = Nokogiri::HTML(@rev_html)
    @citation_index = ReferenceListParser.new(doc).citations
    # The parse API wraps article content in div.mw-parser-output. Prose
    # paragraphs are its direct <p> children; selecting only those excludes
    # content inside infoboxes, tables and figures.
    doc.css('.mw-parser-output > p').each { |paragraph| extract_claims_from(paragraph) }
  end

  # Each marker is attributed a claim running from the previous marker (or
  # the start of the containing sentence) up to the marker itself, plus the
  # full sentence for context. Adjacent markers like `.[1][2]` sit at the
  # same offset, so the later ones add their citations to the same claim.
  def extract_claims_from(paragraph)
    text, markers = walk_paragraph(paragraph)
    sentences = sentence_ranges(text)
    last_claim = nil
    prev_offset = nil
    markers.each do |offset, citation|
      if offset == prev_offset
        last_claim[:citations] << citation unless last_claim.nil?
      else
        last_claim = record_claim(text, sentences, offset, prev_offset, citation)
      end
      prev_offset = offset
    end
  end

  # Accumulates a paragraph's prose into a text buffer, recording the
  # buffer offset of each resolvable reference marker. The marker's own
  # text (the rendered "[1]") never enters the buffer.
  def walk_paragraph(paragraph)
    text = +''
    markers = []
    paragraph.children.each do |node|
      if reference_marker?(node)
        citation = resolve_citation(node)
        markers << [text.length, citation] unless citation.nil?
      else
        text << node.text
      end
    end
    [text, markers]
  end

  # Returns [start, end] offset pairs for each sentence in the text.
  def sentence_ranges(text)
    starts = [0]
    text.scan(SENTENCE_BOUNDARY) { starts << Regexp.last_match.end(0) }
    starts.each_cons(2).to_a << [starts.last, text.length]
  end

  def reference_marker?(node)
    node.element? && node.name == 'sup' && node.classes.include?('reference')
  end

  def resolve_citation(sup_node)
    href = sup_node.at_css('a')&.[]('href')
    return nil if href.nil?
    @citation_index[href.delete_prefix('#')]
  end

  def record_claim(text, sentences, offset, prev_offset, citation)
    range = sentences.find { |start, fin| offset > start && offset <= fin }
    return nil if range.nil?
    claim_start = [range.first, prev_offset || 0].max
    claim = { claim: text[claim_start...offset].squish,
              sentence: text[range.first...range.last].squish,
              citations: [citation] }
    @claims << claim
    claim
  end

  def filter_claims
    @claims.select! { |claim| claim[:sentence].length >= MIN_CLAIM_LENGTH }
    @claims.select! { |claim| claim[:claim].present? }
    return if @only_within.nil?
    @claims.select! { |claim| @only_within.include?(claim[:claim]) }
  end
end
