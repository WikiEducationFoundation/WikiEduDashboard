# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"
require_dependency "#{Rails.root}/lib/claim_verification/claim_citation_extractor"
require_dependency "#{Rails.root}/lib/claim_verification/sentence_highlighter"

# Renders an article's current revision and wraps each cited claim's sentence —
# the prose the citation is attached to, the content a student actually has to
# verify — in a `cv-claim` span so it can be highlighted and clicked in the
# ArticleViewer-based claim exercise. The real article HTML is preserved; we only
# add a span (with class and data attributes) around the cited sentences, so the
# client can highlight them and, on click, show the claim's source and let the
# student take it. If a sentence can't be located we fall back to tagging just its
# `[n]` citation marker.
class AnnotateArticleClaims
  attr_reader :html, :mw_rev_id

  def initialize(article)
    @article = article
    perform
  end

  private

  def perform
    @mw_rev_id = WikiApi::ArticleContent.new(@article.wiki).latest_revision_id(@article.title)
    return if @mw_rev_id.nil?
    source_html = GetRevisionHtmlWithCitations.new(@mw_rev_id, @article.wiki,
                                                   diff_mode: false).html
    @html = source_html && annotate(source_html)
  end

  def annotate(source_html)
    extractor = ClaimVerification::ClaimCitationExtractor.new(source_html)
    citations_by_ref_id = extractor.citations.index_by(&:ref_id)
    doc = Nokogiri::HTML.fragment(source_html)
    extractor.claims.each { |claim| highlight(doc, claim, citations_by_ref_id) }
    absolutize_links(doc)
    doc.to_html
  end

  # MediaWiki parser output uses root-relative links (/wiki/...); make them
  # absolute so they work when this HTML is rendered in the viewer. In-page
  # anchors (#cite_note-...) are left alone so footnote links still work.
  def absolutize_links(doc)
    base = @article.wiki.base_url
    doc.css('a[href^="/"]').each { |link| link['href'] = "#{base}#{link['href']}" }
  end

  # Wrap the claim's sentence at the marker for its (first available) citation.
  # We try each matching marker and keep the one whose preceding prose matches the
  # sentence; if none does, we tag the first marker as a fallback.
  def highlight(doc, claim, citations_by_ref_id)
    ref_id = claim.ref_ids.find { |id| citations_by_ref_id.key?(id) }
    return if ref_id.nil?
    data = data_for(claim, ref_id, citations_by_ref_id[ref_id])
    markers = doc.css("sup.reference a[href='##{ref_id}']").map(&:parent)
    return if markers.empty?
    wrapped = markers.any? do |marker|
      ClaimVerification::SentenceHighlighter.new(marker:, sentence: claim.sentence, data:).wrap
    end
    tag(markers.first, data) unless wrapped
  end

  def data_for(claim, ref_id, citation)
    { 'data-ref-id' => ref_id, 'data-sentence' => claim.sentence,
      'data-cite-text' => citation.cite_text,
      'data-source-url' => citation.urls.first || citation.archive_urls.first }
  end

  # Fallback: tag just the citation marker when the sentence can't be located.
  def tag(marker, data)
    marker['class'] = "#{marker['class']} cv-claim".strip
    data.each { |key, value| marker[key] = value if value }
  end
end
