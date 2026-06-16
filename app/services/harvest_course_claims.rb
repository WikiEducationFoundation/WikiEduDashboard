# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"

# Harvests cited claims from every mainspace article a (past-term) course
# worked on, into the verification-claim pool, tagged with the course's
# subject. For each article it renders the current revision's HTML with
# citations intact and feeds it through HarvestRevisionClaims.
#
# Network-bound: one parser API call per article. The choice to harvest each
# article's *latest* revision (rather than its end-of-course state) is
# isolated in #latest_revision_id so it can be revisited. Per-article failures
# are logged and skipped so one bad article does not abort the course.
class HarvestCourseClaims
  attr_reader :claims

  DEFAULT_ARTICLE_LIMIT = 50

  def initialize(course, article_limit: DEFAULT_ARTICLE_LIMIT)
    @course = course
    @article_limit = article_limit
    @claims = []
    perform
  end

  private

  def perform
    articles.each { |article| @claims.concat(harvest_article(article)) }
  end

  def articles
    @course.articles.live.namespace(Article::Namespaces::MAINSPACE).first(@article_limit)
  end

  def harvest_article(article)
    rev_id = latest_revision_id(article)
    return [] if rev_id.nil?
    html = revision_html(rev_id, article)
    return [] if html.nil?
    store_claims(article, rev_id, html)
  rescue StandardError => e
    Rails.logger.warn("HarvestCourseClaims: #{article.title} failed: #{e.message}")
    []
  end

  def store_claims(article, rev_id, html)
    HarvestRevisionClaims.new(html:, wiki: article.wiki, subject: @course.subject,
                              article:, article_title: article.title,
                              mw_rev_id: rev_id, source_course: @course).claims
  end

  def latest_revision_id(article)
    WikiApi::ArticleContent.new(article.wiki).latest_revision_id(article.title)
  end

  def revision_html(rev_id, article)
    GetRevisionHtmlWithCitations.new(rev_id, article.wiki, diff_mode: false).html
  end
end
