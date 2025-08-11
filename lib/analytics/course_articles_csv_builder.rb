# frozen_string_literal: true

require 'csv'

class CourseArticlesCsvBuilder
  include ArticleHelper

  def initialize(course)
    @course = course
    set_articles_edited
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    article_rows.each do |row|
      csv_data << row
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  def article_rows
    @articles_edited.values.map do |article_data|
      build_row(article_data)
    end
  end

  private

  # rubocop:disable Metrics/AbcSize
  def set_articles_edited
    @articles_edited = {}
    @course.scoped_article_timeslices.includes(article: :wiki).find_each do |act|
      next unless valid_timeslice(act)

      article_edits = @articles_edited[act.article_id] || new_article_entry(act)
      article_edits[:characters] += act.character_sum
      article_edits[:revisions] += act.revision_count
      article_edits[:references] += act.references_count
      article_edits[:new_article] = true if act.new_article
      article_edits[:usernames] += act.user_ids
      @articles_edited[act.article_id] = article_edits
    end
  end
  # rubocop:enable Metrics/AbcSize

  def new_article_entry(act)
    article = act.article
    {
      new_article: false,
      characters: 0,
      revisions: 0,
      references: 0,
      usernames: [],
      title: article.title,
      namespace: article.namespace,
      url: article.url,
      deleted: article.deleted,
      pageview_url: pageview_url(article),
      wiki_domain: article.wiki.domain,
      rating: article.rating
    }
  end

  CSV_HEADERS = %w[
    title
    rating
    namespace
    wiki
    usernames
    url
    edit_count
    characters_added
    references_added
    new
    deleted
    pageviews_link
  ].freeze

  # rubocop:disable Metrics/AbcSize
  def build_row(article_data)
    row = [article_data[:title]]
    row << article_data[:rating]
    row << article_data[:namespace]
    row << article_data[:wiki_domain]
    row << to_usernames(article_data[:usernames])
    row << article_data[:url]
    row << article_data[:revisions]
    row << article_data[:characters]
    row << article_data[:references]
    row << article_data[:new_article]
    row << article_data[:deleted]
    row << article_data[:pageview_url]
  end
  # rubocop:enable Metrics/AbcSize

  # If the Article record is missing or the ACT is empty or it's untracked
  # then we don't want to take that ACT into account for the report.
  def valid_timeslice(act)
    act.article && act.revision_count.positive? && act.tracked
  end

  def to_usernames(user_ids)
    User.where(id: user_ids).pluck(:username).join(', ')
  end

  # Example:
  # https://pageviews.toolforge.org/?project=en.wikipedia.org&platform=all-access&agent=user&redirects=0&start=2015-07-01&end=2017-01-16&pages=Mossack_Fonseca
  PAGEVIEWS_BASE_URL = 'https://pageviews.toolforge.org/?platform=all-access&agent=user'
  def pageview_url(article)
    PAGEVIEWS_BASE_URL + pageviews_range_param + pageview_article_params(article)
  end

  def pageview_article_params(article)
    "&project=#{article.wiki.domain}&pages=#{article.escaped_full_title}"
  end

  def pageviews_range_param
    # Pageviews tool expects YYYY-MM-DD date formats.
    # When a future end date is provided, the current date is used instead.
    @date_range ||= "&start=#{@course.start.strftime('%Y-%m-%d')}&end=2099-01-01"
  end
end
