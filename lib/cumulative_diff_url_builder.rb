# frozen_string_literal: true

#= Builds a cumulative diff URL for an ArticlesCourses record by querying
#= the MediaWiki API to find the earliest and latest revisions made by the
#= course's editors within the course date range.
#=
#= Makes 2 API requests per editor (earliest + latest revision), so for an
#= article with N editors this issues 2N sequential requests.
class CumulativeDiffUrlBuilder
  def initialize(articles_course)
    @articles_course = articles_course
    @article = articles_course.article
    @course = articles_course.course
    @wiki = @article.wiki
    @wiki_api = WikiApi.new(@wiki)
  end

  def url
    usernames = User.where(id: @articles_course.user_ids).pluck(:username)
    return nil if usernames.empty?

    article_title = @article.escaped_full_title
    start_date = @course.start.iso8601
    end_date = @course.end.iso8601

    first_rev = earliest_revision(article_title, usernames, start_date, end_date)
    last_rev = latest_revision(article_title, usernames, start_date, end_date)
    return nil unless first_rev && last_rev

    build_diff_url(first_rev, last_rev)
  end

  private

  def build_diff_url(first_rev, last_rev)
    parent_id = first_rev['parentid']
    last_id = last_rev['revid']
    # parentid is 0 when the student created the article; use revid instead
    old_id = parent_id.zero? ? first_rev['revid'] : parent_id
    "#{@wiki.base_url}/w/index.php?oldid=#{old_id}&diff=#{last_id}"
  end

  def earliest_revision(title, usernames, start_date, end_date)
    revisions = usernames.filter_map do |username|
      fetch_revision(title, username, start_date, end_date, direction: 'newer')
    end
    revisions.min_by { |rev| rev['timestamp'] }
  end

  def latest_revision(title, usernames, start_date, end_date)
    revisions = usernames.filter_map do |username|
      fetch_revision(title, username, start_date, end_date, direction: 'older')
    end
    revisions.max_by { |rev| rev['timestamp'] }
  end

  def fetch_revision(title, username, start_date, end_date, direction:)
    params = revision_query_params(title, username, start_date, end_date, direction)
    response = @wiki_api.query(params)
    parse_revision(response)
  end

  def revision_query_params(title, username, start_date, end_date, direction)
    params = {
      prop: 'revisions', titles: title, rvprop: 'timestamp|user|ids',
      rvuser: username, rvdir: direction, rvlimit: 1
    }
    if direction == 'newer'
      params.merge(rvstart: start_date, rvend: end_date)
    else
      params.merge(rvstart: end_date, rvend: start_date)
    end
  end

  def parse_revision(response)
    return nil unless response&.data
    pages = response.data['pages']
    return nil unless pages
    page = pages.values.first
    page&.dig('revisions', 0)
  end
end
