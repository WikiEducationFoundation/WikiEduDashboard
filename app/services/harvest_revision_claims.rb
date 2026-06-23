# frozen_string_literal: true

# Extracts every cited claim from one revision's HTML and stores each
# (claim, cited source) pair as a VerificationClaim pool entry. Nothing is
# filtered out: `offline_source` records whether the citation exposed an
# openable URL, and `courses_user` records the enrolling student when the
# caller is harvesting that student's own added content (eg the added side of
# a diff). Idempotent — re-running on the same revision does not duplicate
# pool entries.
class HarvestRevisionClaims
  attr_reader :claims

  def initialize(html:, wiki:, subject: nil, article: nil, article_title: nil,
                 mw_rev_id: nil, source_course: nil, courses_user: nil, alert: nil)
    @html = html
    @wiki = wiki
    @subject = subject
    @article = article
    @article_title = article_title
    @mw_rev_id = mw_rev_id
    @source_course = source_course
    @courses_user = courses_user
    @alert = alert
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
      citation = @citations_by_ref_id[ref_id]
      next if citation.nil?
      store(claim, citation, ref_id)
    end
  end

  def store(claim, citation, ref_id)
    VerificationClaim.find_or_create_by(
      wiki: @wiki, mw_rev_id: @mw_rev_id, ref_id:, sentence: claim.sentence
    ) { |record| record.assign_attributes(attributes_for(claim, citation)) }
  end

  def attributes_for(claim, citation)
    {
      context: claim.context, cite_text: citation.cite_text,
      source_url: citation.urls.first, archive_url: citation.archive_urls.first,
      offline_source: citation.offline_source?, article: @article,
      article_title: @article_title, subject: @subject,
      source_course: @source_course, courses_user: @courses_user, alert: @alert
    }
  end
end
