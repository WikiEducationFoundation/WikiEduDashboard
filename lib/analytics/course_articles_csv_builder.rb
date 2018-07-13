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

  def set_articles_edited
    @articles_edited = {}
    @course.all_revisions.includes(article: :wiki).map do |edit|
      article_edits = @articles_edited[edit.article_id] || new_article_entry(edit)
      article_edits[:characters][edit.mw_rev_id] = edit.characters
      article_edits[:new_article] = true if edit.new_article
      # highest view count of all revisions for this article is the total for the article
      article_edits[:views] = edit.views if edit.views > article_edits[:views]
      @articles_edited[edit.article_id] = article_edits
    end
  end

  def new_article_entry(edit)
    article = edit.article
    {
      new_article: false,
      views: 0,
      characters: {},
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
    namespace
    wiki
    url
    edit_count
    characters_added
    new
    deleted
    pageviews
    pageviews_link
  ].freeze

  def build_row(article_data)
    row = [article_data[:title]]
    row << article_data[:namespace]
    row << article_data[:wiki_domain]
    row << article_data[:url]
    row << article_data[:characters].count
    row << character_sum(article_data)
    row << article_data[:new_article]
    row << article_data[:deleted]
    row << article_data[:views]
    row << article_data[:pageview_url]
  end

  def character_sum(article_data)
    article_data[:characters].values.inject(0) do |sum, characters|
      characters&.positive? ? sum + characters : sum
    end
  end

  # Example:
  # https://tools.wmflabs.org/pageviews/?project=en.wikipedia.org&platform=all-access&agent=user&start=2015-07-01&end=2017-01-16&pages=Mossack_Fonseca
  PAGEVIEWS_BASE_URL = 'https://tools.wmflabs.org/pageviews/?platform=all-access&agent=user'
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
