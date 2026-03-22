# frozen_string_literal: true

#= Builds a cumulative diff URL for an ArticlesCourses record by querying
#= the MediaWiki API to find the earliest and latest revisions made by the
#= course's editors within the course date range.
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

    parent_id = first_rev['parentid']
    last_id = last_rev['revid']
    "#{@wiki.base_url}/w/index.php?oldid=#{parent_id}&diff=#{last_id}"
  end

  private

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
    params = {
      prop: 'revisions',
      titles: title,
      rvprop: 'timestamp|user|ids',
      rvuser: username,
      rvdir: direction,
      rvlimit: 1
    }

    if direction == 'newer'
      params[:rvstart] = start_date
      params[:rvend] = end_date
    else
      params[:rvstart] = end_date
      params[:rvend] = start_date
    end

    response = @wiki_api.query(params)
    return nil unless response&.data
    pages = response.data['pages']
    return nil unless pages
    page = pages.values.first
    page&.dig('revisions', 0)
  end
end
