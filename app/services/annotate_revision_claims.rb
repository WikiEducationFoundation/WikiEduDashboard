# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/claim_citation_extractor"
require_dependency "#{Rails.root}/lib/claim_verification/rollout_list"
require_dependency "#{Rails.root}/lib/claim_verification/sentence_highlighter"

# Renders an article at the exact revision a mainspace AiEditAlert flagged and
# wraps — in a `cv-claim` span — only the cited sentences that were *added* in
# that revision (the pre-harvested pool claims for this article+revision, less
# any curated out via the rollout config), so the ArticleViewer can highlight
# them and let the student take one on. The full revision is rendered (not the
# diff) so MediaWiki's real citation markers and sentence positions are present;
# each highlighted span carries the stored VerificationClaim's id and display
# data, so the client never re-derives them. If a sentence can't be located we
# fall back to tagging its `[n]` marker.
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
    # One span per pool claim: the same sentence can be reached through more than
    # one of the extractor's claims (a sentence carrying several citations), and
    # highlighting it twice would both nest the spans and inflate the claim count.
    highlighted = Set.new
    extractor.claims.each do |claim|
      harvested = harvested_claims[normalize(claim.sentence)]
      next if harvested.nil? || highlighted.include?(harvested.id)
      highlighted << harvested.id if highlight(doc, claim, citations_by_ref_id, harvested)
    end
    absolutize_links(doc)
    doc.to_html
  end

  # Wrap the (added) claim's sentence where that sentence actually appears in the
  # prose; the span data comes from the stored pool claim. The citation marker is
  # deliberately not used to place the highlight — see SentenceHighlighter — only
  # to identify the source and to carry the fallback tag when the sentence can't
  # be found in any paragraph.
  def highlight(doc, claim, citations_by_ref_id, harvested)
    ref_id = claim.ref_ids.find { |id| citations_by_ref_id.key?(id) }
    return false if ref_id.nil?
    data = data_for(harvested, ref_id)
    return true if wrap_sentence(doc, claim.sentence, data)
    marker = markers_for(doc, ref_id).first
    return false if marker.nil?
    tag(marker, data)
    true
  end

  # The prose paragraph holding this sentence, wrapped. Paragraphs are searched in
  # document order because a sentence occurs once in an article's prose in all but
  # pathological cases; the highlighter itself refuses a sentence already inside
  # another claim's span.
  def wrap_sentence(doc, sentence, data)
    prose_paragraphs(doc).any? do |paragraph|
      ClaimVerification::SentenceHighlighter.new(paragraph:, sentence:, data:).wrap
    end
  end

  # The paragraphs the segmenter drew its sentences from: article prose, not the
  # contents of tables, figures or the reference list (which
  # ClaimCitationExtractor drops before segmenting).
  def prose_paragraphs(doc)
    doc.css('p').reject do |paragraph|
      paragraph.ancestors.any? do |ancestor|
        %w[table figure].include?(ancestor.name) ||
          ancestor['class'].to_s.split.include?('references')
      end
    end
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
  # wins when a sentence carries more than one citation), minus the claims
  # curated out of the exercise. The exclusion is applied after each sentence's
  # representative is picked, not in the query: a sentence with several
  # citations has one pool row per citation, and excluding only the row the
  # student sees would just promote the next one. What's excluded is the
  # sentence as displayed — the thing the curators reviewed.
  def harvested_claims
    @harvested_claims ||= VerificationClaim.where(article_id: @article.id, mw_rev_id: @mw_rev_id)
                                           .order(:id).each_with_object({}) do |claim, map|
      map[normalize(claim.sentence)] ||= claim
    end.reject { |_, claim| ClaimVerification::RolloutList.excluded?(claim.id) }
  end

  def normalize(text)
    text.to_s.gsub(/\s+/, ' ').strip
  end
end
