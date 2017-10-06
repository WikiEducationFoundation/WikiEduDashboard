# frozen_string_literal: true

require 'csv'

class CourseArticlesCsvBuilder
  include ArticleHelper

  def initialize(course)
    @course = course
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    @course.pages_edited.includes(:wiki, :revisions).each do |article|
      csv_data << row(article)
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  private

  CSV_HEADERS = %w[
    title
    namespace
    wiki
    url
    edit_count
    new
    deleted
    pageviews
    pageviews_link
  ].freeze
  def row(article)
    article_stats = ArticleStats.new(@course, article)

    row = [article.title]
    row << article.namespace
    row << article.wiki.domain
    row << article.url
    row << article_stats.edit_count
    row << article_stats.new?
    row << article.deleted
    row << article_stats.pageviews
    row << pageview_url(article)
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

  class ArticleStats
    def initialize(course, article)
      @course_article_revisions = course.all_revisions.where(article: article)
    end

    def new?
      @course_article_revisions.where(new_article: true).any?
    end

    def edit_count
      @course_article_revisions.count
    end

    def pageviews
      @course_article_revisions.maximum(:views)
    end
  end
end
