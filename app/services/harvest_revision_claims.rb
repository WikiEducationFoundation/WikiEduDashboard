# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/citation"

# Extracts every cited claim from one revision's HTML and stores each
# (claim, cited source) pair as a VerificationClaim pool entry. Nothing is
# filtered out: `offline_source` records whether the citation exposed an
# openable URL, and `courses_user` records the enrolling student when the
# caller is harvesting that student's own added content (eg the added side of
# a diff).
#
# When harvesting a diff, a sentence may cite a *named* reference defined
# elsewhere in the article; that reference renders as a cite error in the
# diff-only HTML. `full_html_provider` (called lazily — only when such an
# unresolved citation is encountered) supplies the full-revision HTML so the
# citation can be matched by ref name and resolved. Re-running upserts pool
# entries (keyed by wiki + revision + ref + sentence), so a full re-harvest
# refreshes citations and timestamps in place without duplicating.
class HarvestRevisionClaims
  attr_reader :claims

  def initialize(html:, wiki:, subject: nil, article: nil, article_title: nil,
                 mw_rev_id: nil, source_course: nil, courses_user: nil, alert: nil,
                 mw_rev_timestamp: nil, full_html_provider: nil)
    @html = html
    @wiki = wiki
    @subject = subject
    @article = article
    @article_title = article_title
    @mw_rev_id = mw_rev_id
    @source_course = source_course
    @courses_user = courses_user
    @alert = alert
    @mw_rev_timestamp = mw_rev_timestamp
    @full_html_provider = full_html_provider
    @claims = []
    perform
  end

  private

  def perform
    extraction = ExtractClaimsAndSources.new(@html)
    @citations_by_ref_id = extraction.citations.index_by(&:ref_id)
    @claims = extraction.claims.flat_map { |claim| pool_entries(claim) }
  end

  def pool_entries(claim)
    claim.ref_ids.filter_map do |ref_id|
      citation = resolve_citation(ref_id)
      next if citation.nil?
      store(claim, citation, ref_id)
    end
  end

  # Prefer the citation from this render; if it is missing or unresolved (a
  # named ref defined elsewhere), fall back to the full-revision render's
  # citation, matched by ref name.
  def resolve_citation(ref_id)
    citation = @citations_by_ref_id[ref_id]
    return citation if citation && !citation.unresolved?
    name = ClaimVerification::Citation.ref_name(ref_id)
    full_citations_by_name[name]&.first || citation
  end

  def full_citations_by_name
    @full_citations_by_name ||= load_full_citations.group_by(&:ref_name)
  end

  def load_full_citations
    html = @full_html_provider&.call
    return [] if html.blank?
    ExtractClaimsAndSources.new(html).citations
  end

  def store(claim, citation, ref_id)
    record = VerificationClaim.find_or_initialize_by(
      wiki: @wiki, mw_rev_id: @mw_rev_id, ref_id:, sentence: claim.sentence
    )
    record.update!(attributes_for(claim, citation))
    record
  end

  def attributes_for(claim, citation)
    {
      context: claim.context, cite_text: citation.cite_text,
      source_url: citation.urls.first, archive_url: citation.archive_urls.first,
      offline_source: citation.offline_source?, article: @article,
      article_title: @article_title, subject: @subject, alert: @alert,
      mw_rev_timestamp: @mw_rev_timestamp, source_course: @source_course,
      courses_user: @courses_user
    }
  end
end
