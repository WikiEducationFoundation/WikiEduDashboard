# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"
require_dependency "#{Rails.root}/lib/reference_list_parser"

# Extracts (factual claim, cited source) pairs from a Wikipedia article,
# for use in source verification exercises. Each claim is a sentence from
# the article's prose, paired with the details of the reference(s) cited
# for it. Pass either an article +title+ (the latest revision is used) or
# a specific +mw_rev_id+. When +only_within+ is given — a plain text
# corpus, such as the text added by particular students — only claims
# whose text appears within that corpus are kept.
class ExtractClaimsAndSources
  # Claims shorter than this are dropped, to avoid sentence fragments
  # produced by mid-sentence reference markers.
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

  # Walks a paragraph's nodes, accumulating prose into a buffer. Each
  # reference marker gets attributed to the sentence preceding it; the
  # marker's own text (the rendered "[1]") never enters the buffer.
  def extract_claims_from(paragraph)
    buffer = +''
    last_claim = nil
    paragraph.children.each do |node|
      unless reference_marker?(node)
        buffer << node.text
        next
      end
      citation = resolve_citation(node)
      next if citation.nil?
      last_claim = record_claim(citation, buffer, last_claim)
      buffer = +''
    end
  end

  def reference_marker?(node)
    node.element? && node.name == 'sup' && node.classes.include?('reference')
  end

  def resolve_citation(sup_node)
    href = sup_node.at_css('a')&.[]('href')
    return nil if href.nil?
    @citation_index[href.delete_prefix('#')]
  end

  # A marker with no preceding text (as in adjacent markers like `.[1][2]`)
  # adds its citation to the previous claim instead of starting a new one.
  def record_claim(citation, buffer, last_claim)
    claim_text = last_sentence(buffer)
    if claim_text.empty?
      last_claim[:citations] << citation unless last_claim.nil?
      return last_claim
    end
    claim = { claim: claim_text, citations: [citation] }
    @claims << claim
    claim
  end

  def last_sentence(text)
    text.squish.split(SENTENCE_BOUNDARY).last.to_s.strip
  end

  def filter_claims
    @claims.select! { |claim| claim[:claim].length >= MIN_CLAIM_LENGTH }
    return if @only_within.nil?
    @claims.select! { |claim| @only_within.include?(claim[:claim]) }
  end
end
