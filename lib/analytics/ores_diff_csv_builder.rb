# frozen_string_literal: true

require 'csv'
require_dependency "#{Rails.root}/lib/importers/revision_score_importer"
require_dependency "#{Rails.root}/app/helpers/article_helper"

class OresDiffCsvBuilder
  include ArticleHelper

  def initialize(courses)
    @courses = courses
  end

  CSV_HEADERS = %w[
    article_title
    ores_before
    ores_after
    bytes_added
    article_url
    course
  ].freeze

  def articles_to_csv
    csv_data = [CSV_HEADERS]
    @courses.each do |course|
      course.articles_courses.includes(:article)
            .where(articles: { wiki_id: supported_wiki_ids, deleted: false })
            .each do |articles_course|
        csv_data << article_row(articles_course, course)
      end
    end

    CSV.generate { |csv| csv_data.uniq.each { |line| csv << line } }
  end

  def article_row(articles_course, course)
    article = articles_course.article
    ordered_revisions = articles_course.all_revisions.order('date ASC')
    first_revision = ordered_revisions.first
    last_revision = ordered_revisions.last
    [
      article.title,
      first_revision&.wp10_previous || 0.0,
      last_revision&.wp10 || 0.0,
      articles_course.character_sum,
      article.url,
      course.slug
    ]
  end

  def supported_wiki_ids
    @ids ||= Wiki.where(language: LiftWingApi::AVAILABLE_WIKIPEDIAS,
                        project: 'wikipedia').pluck(:id)
  end
end
