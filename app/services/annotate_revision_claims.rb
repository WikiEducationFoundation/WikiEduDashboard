# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/claim_citation_extractor"
require_dependency "#{Rails.root}/lib/claim_verification/sentence_highlighter"

# Renders an article at the exact revision a mainspace AiEditAlert flagged and
# wraps — in a `cv-claim` span — only the cited sentences that were *added* in
# that revision (the pre-harvested pool claims for this article+revision), so the
# ArticleViewer can highlight them and let the student take one on. The full
# revision is rendered (not the diff) so MediaWiki's real citation markers and
# sentence positions are present; each highlighted span carries the stored
# VerificationClaim's id and display data, so the client never re-derives them.
# If a sentence can't be located we fall back to tagging its `[n]` marker.
class AnnotateRevisionClaims
  attr_reader :html, :mw_rev_id

  def initialize(article:, mw_rev_id:)
    @article = article
    @mw_rev_id = mw_rev_id
    perform
  end

  private

  def perform
    return if harvested_claims.empty?
    source_html = GetRevisionHtmlWithCitations.new(@mw_rev_id, @article.wiki,
                                                   diff_mode: false).html
    @html = source_html && annotate(source_html)
  end

  def annotate(source_html)
    extractor = ClaimVerification::ClaimCitationExtractor.new(source_html)
    citations_by_ref_id = extractor.citations.index_by(&:ref_id)
    doc = Nokogiri::HTML.fragment(source_html)
    extractor.claims.each do |claim|
      harvested = harvested_claims[normalize(claim.sentence)]
      highlight(doc, claim, citations_by_ref_id, harvested) if harvested
    end
    absolutize_links(doc)
    doc.to_html
  end

  # Wrap the (added) claim's sentence at its citation marker. Markers are located
  # by the ref ids extracted from this full revision; the span data comes from the
  # stored pool claim. Falls back to tagging just the marker if the sentence can't
  # be located in the prose.
  def highlight(doc, claim, citations_by_ref_id, harvested)
    ref_id = claim.ref_ids.find { |id| citations_by_ref_id.key?(id) }
    return if ref_id.nil?
    data = data_for(harvested, ref_id)
    markers = markers_for(doc, ref_id)
    return if markers.empty?
    wrapped = markers.any? do |marker|
      ClaimVerification::SentenceHighlighter.new(marker:, sentence: claim.sentence, data:).wrap
    end
    tag(markers.first, data) unless wrapped
  end

  # The citation markers (the <sup>) for this ref id. Matched by reading each
  # reference link's href in Ruby rather than via an interpolated CSS attribute
  # selector, because a ref id can contain characters that break such a selector
  # (eg an apostrophe, from a named ref like <ref name="O'Brien 2020">, which
  # MediaWiki keeps in the cite_note id).
  def markers_for(doc, ref_id)
    doc.css('sup.reference a')
       .select { |link| link['href'] == "##{ref_id}" }
       .map(&:parent)
  end

  def data_for(harvested, ref_id)
    { 'data-claim-id' => harvested.id.to_s, 'data-ref-id' => ref_id,
      'data-sentence' => harvested.sentence, 'data-cite-text' => harvested.cite_text,
      'data-source-url' => harvested.source_url || harvested.archive_url }
  end

  # Fallback: tag just the citation marker when the sentence can't be located.
  # Make it a focusable control and give it the sentence as its accessible name,
  # since the bare "[n]" marker text would tell a screen-reader user nothing.
  def tag(marker, data)
    marker['class'] = "#{marker['class']} cv-claim".strip
    marker['role'] = 'button'
    marker['tabindex'] = '0'
    marker['aria-label'] = data['data-sentence'] if data['data-sentence']
    data.each { |key, value| marker[key] = value if value }
  end

  # MediaWiki parser output uses root-relative links (/wiki/...); make them
  # absolute so they work when this HTML is rendered in the viewer. In-page
  # anchors (#cite_note-...) are left alone so footnote links still work, and so
  # are protocol-relative URLs (//host/...), which would otherwise be
  # double-prefixed into a broken link.
  def absolutize_links(doc)
    base = @article.wiki.base_url
    doc.css('a[href^="/"]:not([href^="//"])').each do |link|
      link['href'] = "#{base}#{link['href']}"
    end
  end

  # The pool claims added in this revision, keyed by normalized sentence (first
  # wins when a sentence carries more than one citation).
  def harvested_claims
    @harvested_claims ||= VerificationClaim.where(article_id: @article.id, mw_rev_id: @mw_rev_id)
                                           .order(:id).each_with_object({}) do |claim, map|
      map[normalize(claim.sentence)] ||= claim
    end
  end

  def normalize(text)
    text.to_s.gsub(/\s+/, ' ').strip
  end
end
