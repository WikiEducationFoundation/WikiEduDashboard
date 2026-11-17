# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

# Creates an ArticleAudit from a page, revision or diff URL and queues it.
#
# An audit covers one whole revision. A page URL audits the page's latest
# revision; a permanent link (oldid=) audits that revision; a diff URL audits
# the newer revision of the diff, in full.
#
# On failure, `audit` is nil and `error` is an error code (invalid_url or
# revision_not_found), which the page shows as is.
#
# With enqueue: false the audit is only created, for a caller that runs it
# itself (as docs/analytics_scripts/article_audit/evaluate.rb does).
class CreateArticleAudit
  attr_reader :audit, :error

  def initialize(url:, requester:, enqueue: true)
    @url = url.to_s.strip
    @requester = requester
    @enqueue = enqueue
    perform
  end

  private

  def perform
    parser = WikiUrlParser.new(@url)
    @wiki = parser.wiki
    return @error = :invalid_url if @wiki.nil?
    @rev_id = revision_id(parser)
    return @error = :revision_not_found if @rev_id.nil?

    @audit = ArticleAudit.create!(wiki: @wiki, mw_rev_id: @rev_id, url: @url.first(1000),
                                  article_title: parser.title, requester: @requester,
                                  article: matching_article(parser.title))
    ArticleAuditWorker.run(@audit) if @enqueue
  end

  def revision_id(parser)
    target = parser.revision_target
    return target[:rev_id] if target
    # A diff=next URL selects a revision we can't resolve from the URL alone.
    return if parser.revision_selector? || parser.title.nil?
    WikiApi::ArticleContent.new(@wiki).latest_revision_id(parser.title)
  end

  def matching_article(title)
    return if title.nil?
    Article.find_by(wiki: @wiki, title: title.tr(' ', '_'), namespace: 0, deleted: false)
  end
end
