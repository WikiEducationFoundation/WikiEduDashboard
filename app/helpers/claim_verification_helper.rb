# frozen_string_literal: true

# View helpers for the student claim-verification exercise (issue #6910).
module ClaimVerificationHelper
  include MediawikiUrlHelper

  # URL the student opens to read the cited source: the live source if present,
  # otherwise the archived copy. Nil for offline-only citations.
  def claim_source_url(claim)
    claim.source_url.presence || claim.archive_url.presence
  end

  # URL of the claim's Wikipedia article as of the flagged revision the claim
  # was harvested from — the version the student read in the exercise — anchored
  # at the cited footnote (ref_id, eg "cite_note-5") so the reader lands on the
  # citation and can use its caret backlink to find where the claim sits in the
  # prose. The flagged edit may since have been reverted or reworded, so the
  # current article is only the fallback, for a claim with no recorded revision.
  # Nil when there is neither a revision nor a title to link to.
  def claim_article_url(claim)
    url = claim_page_url(claim)
    return if url.nil?
    claim.ref_id.present? ? "#{url}##{claim.ref_id}" : url
  end

  private

  def claim_page_url(claim)
    return if claim.wiki.nil?
    return "#{claim.wiki.base_url}/w/index.php?oldid=#{claim.mw_rev_id}" if claim.mw_rev_id
    return if claim.article_title.blank?
    "#{claim.wiki.base_url}/wiki/#{url_encoded_mediawiki_title(claim.article_title)}"
  end
end
