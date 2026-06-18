# frozen_string_literal: true

# View helpers for the student claim-verification exercise (issue #6910).
module ClaimVerificationHelper
  include MediawikiUrlHelper
  # On-wiki worksheet template the sandbox is preloaded with. This page must be
  # created on-wiki by an operator, like Template:Dashboard.wikiedu.org_draft_template.
  CLAIM_VERIFICATION_PRELOAD_TEMPLATE = 'Template:Dashboard.wikiedu.org_claim_verification'
  # Subpage, under the student's user page, where they do the exercise.
  SANDBOX_SUBPAGE = 'Claim_verification_exercise'

  # URL the student opens to read the cited source: the live source if present,
  # otherwise the archived copy. Nil for offline-only citations.
  def claim_source_url(claim)
    claim.source_url.presence || claim.archive_url.presence
  end

  # URL of the source Wikipedia article, anchored at the cited footnote (ref_id,
  # eg "cite_note-5") so the student lands on the citation and can use its caret
  # backlink to find where the claim sits in the prose. The anchor is
  # best-effort against the current article and may drift as the article
  # changes. Nil when we have no article title to link to.
  def claim_article_url(claim)
    return if claim.article_title.blank? || claim.wiki.nil?
    url = "#{claim.wiki.base_url}/wiki/#{url_encoded_mediawiki_title(claim.article_title)}"
    claim.ref_id.present? ? "#{url}##{claim.ref_id}" : url
  end

  # Link to the student's sandbox subpage, opened in the editor preloaded with
  # the worksheet template. NOTE: injecting the specific claim/source into the
  # template (via preloadparams, and whether that needs action=edit rather than
  # veaction=edit) is still undecided — see issue #6910. For now the link only
  # preloads the template.
  def claim_verification_sandbox_url(course, user)
    title = "User:#{user.url_encoded_username}/#{SANDBOX_SUBPAGE}"
    "#{course.home_wiki.base_url}/wiki/#{title}" \
      "?veaction=edit&preload=#{CLAIM_VERIFICATION_PRELOAD_TEMPLATE}"
  end
end
