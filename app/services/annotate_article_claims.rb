# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"
require_dependency "#{Rails.root}/lib/claim_verification/claim_citation_extractor"

# Renders an article's current revision and tags each cited claim's in-text
# citation marker (the `[n]` <sup>) so it can be highlighted and clicked in the
# ArticleViewer-based claim exercise. The real article HTML is preserved; we
# only add a class and data attributes to the citation markers we identified as
# cited claims, so the client can highlight them and, on click, show the claim's
# source and let the student take it. (Marker-level for now; sentence-level
# highlighting can refine the same tagging step later.)
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
    extractor.claims.each { |claim| tag_markers(doc, claim, citations_by_ref_id) }
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

  def tag_markers(doc, claim, citations_by_ref_id)
    claim.ref_ids.each do |ref_id|
      citation = citations_by_ref_id[ref_id]
      next if citation.nil?
      doc.css("sup.reference a[href='##{ref_id}']").each do |link|
        tag(link.parent, claim, ref_id, citation)
      end
    end
  end

  def tag(marker, claim, ref_id, citation)
    marker['class'] = "#{marker['class']} cv-claim".strip
    marker['data-ref-id'] = ref_id
    marker['data-sentence'] = claim.sentence
    marker['data-cite-text'] = citation.cite_text
    marker['data-source-url'] = citation.urls.first || citation.archive_urls.first
  end
end
