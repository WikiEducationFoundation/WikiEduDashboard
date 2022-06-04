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
    @course.tracked_revisions.includes(:user, article: :wiki).each do |edit|
      # Skip if the Article record is missing
      next unless edit.article

      article_edits = @articles_edited[edit.article_id] || new_article_entry(edit)
      article_edits[:characters][edit.mw_rev_id] = edit.characters
      article_edits[:references][edit.mw_rev_id] = edit.references_added
      article_edits[:new_article] = true if edit.new_article
      # highest view count of all revisions for this article is the total for the article
      article_edits[:views] = edit.views if edit.views > article_edits[:views]
      article_edits[:username] = edit.user.username
      @articles_edited[edit.article_id] = article_edits
    end
  end
  # rubocop:enable Metrics/AbcSize

  def new_article_entry(edit)
    article = edit.article
    {
      new_article: false,
      views: 0,
      characters: {},
      references: {},
      title: article.title,
      namespace: article.namespace,
      url: article.url,
      deleted: article.deleted,
      pageview_url: pageview_url(article),
      wiki_domain: article.wiki.domain
    }
  end

  CSV_HEADERS = %w[
    title
    rating
    namespace
    wiki
    username
    url
    edit_count
    characters_added
    references_added
    new
    deleted
    pageviews
    pageviews_link
  ].freeze

  # rubocop:disable Metrics/AbcSize
  def build_row(article_data)
    row = [article_data[:title]]
    row << article_data[:rating]
    row << article_data[:namespace]
    row << article_data[:wiki_domain]
    row << article_data[:username]
    row << article_data[:url]
    row << article_data[:characters].count
    row << character_sum(article_data)
    row << references_sum(article_data)
    row << article_data[:new_article]
    row << article_data[:deleted]
    row << article_data[:views]
    row << article_data[:pageview_url]
  end
  # rubocop:enable Metrics/AbcSize

  def character_sum(article_data)
    article_data[:characters].values.inject(0) do |sum, characters|
      characters&.positive? ? sum + characters : sum
    end
  end

  def references_sum(article_data)
    article_data[:references].values.sum(&:to_i)
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
