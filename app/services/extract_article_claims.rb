# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"

# On-demand extraction of the cited claims in an article, for a student to
# browse and choose one to verify. Fetches the article's current revision HTML
# (citations intact) and extracts claims + citations in memory — nothing is
# persisted here. Typically ~1s (one MediaWiki parse call). `mw_rev_id` records
# the revision the claims were read from, so a chosen claim can later be
# persisted with accurate provenance.
class ExtractArticleClaims
  attr_reader :claims, :citations, :mw_rev_id

  def initialize(article)
    @article = article
    @claims = []
    @citations = []
    perform
  end

  private

  def perform
    @mw_rev_id = WikiApi::ArticleContent.new(@article.wiki).latest_revision_id(@article.title)
    return if @mw_rev_id.nil?
    html = GetRevisionHtmlWithCitations.new(@mw_rev_id, @article.wiki, diff_mode: false).html
    return if html.nil?
    extraction = ExtractClaimsAndSources.new(html)
    @claims = extraction.claims
    @citations = extraction.citations
  end
end
