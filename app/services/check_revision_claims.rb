# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"
require_dependency "#{Rails.root}/lib/wiki_api/article_content"
require_dependency "#{Rails.root}/lib/claim_verification/source_fetcher"

# Console-usable entry point for claim verification: takes an article
# or diff URL (the same forms /ai_tools accepts), fetches the revision
# HTML with citations, extracts cited claims, fetches each cited
# source once, and judges each claim against its source.
#
#   check = CheckRevisionClaims.new(url)
#   check.results  # => [{ claim:, citation:, source:, verdict: }, ...]
#
# No persistence — results are in-memory value objects.
class CheckRevisionClaims
  attr_reader :results, :article_title

  def initialize(url, extract_mode: :structural)
    @url = url
    @extract_mode = extract_mode
    @results = []
    parse_url
    perform
  end

  private

  def parse_url
    parser = WikiUrlParser.new(@url)
    @wiki = parser.wiki
    revs = [parser.oldid, parser.diff].compact.reject(&:zero?)

    if parser.diff
      @diff_mode = true
      @rev_id = revs.max
      @from_rev = revs.min if revs.uniq.count == 2
    else
      @diff_mode = false
      @rev_id = parser.oldid || latest_revision(parser.title)
    end
  end

  def latest_revision(title)
    WikiApi::ArticleContent.new(@wiki).latest_revision_id(title)
  end

  def perform
    fetch_html
    return if @html.nil?
    extract_claims_and_citations
    verify_claims
  end

  def fetch_html
    service = GetRevisionHtmlWithCitations.new(@rev_id, @wiki, diff_mode: @diff_mode,
                                                               from_rev: @from_rev)
    @html = service.html
    @article_title = service.article_title
  end

  def extract_claims_and_citations
    extraction = ExtractClaimsAndSources.new(@html, mode: @extract_mode)
    @claims = extraction.claims
    @citations_by_ref_id = extraction.citations.index_by(&:ref_id)
  end

  def verify_claims
    @results = @claims.flat_map do |claim|
      claim.ref_ids.filter_map do |ref_id|
        citation = @citations_by_ref_id[ref_id]
        next if citation.nil?
        verify_claim_against_citation(claim, citation)
      end
    end
  end

  def verify_claim_against_citation(claim, citation)
    source = fetched_source(citation)
    verdict = VerifyClaimAgainstSource.new(claim:, source_text: source.text,
                                           source_status: source.status).verdict
    { claim:, citation:, source:, verdict: }
  end

  # Each distinct citation is fetched only once, no matter how many
  # claims cite it.
  def fetched_source(citation)
    @fetched_sources ||= {}
    @fetched_sources[citation.ref_id] ||=
      ClaimVerification::SourceFetcher.new(citation).result
  end
end
