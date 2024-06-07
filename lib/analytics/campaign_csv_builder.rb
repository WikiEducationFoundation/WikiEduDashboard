# frozen_string_literal: true

require 'csv'
require_dependency "#{Rails.root}/lib/analytics/course_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_articles_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_revisions_csv_builder"
require_dependency "#{Rails.root}/app/workers/campaign_csv_worker"
require "#{Rails.root}/lib/analytics/course_wikidata_csv_builder"

class CampaignCsvBuilder
  def initialize(campaign)
    @campaign = campaign || AllCourses
  end

  def courses_to_csv
    csv_data = [CourseCsvBuilder::CSV_HEADERS]
    @campaign.courses.find_each do |course|
      csv_data << CourseCsvBuilder.new(course).row
    end

    CSV.generate { |csv| csv_data.uniq.each { |line| csv << line } }
  end

  def articles_to_csv
    csv_data = [CourseArticlesCsvBuilder::CSV_HEADERS + ['course_slug']]
    @campaign.courses.find_each do |course|
      CourseArticlesCsvBuilder.new(course).article_rows.each do |row|
        row_with_slug = row + [course.slug]
        csv_data << row_with_slug
      end
    end

    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  def revisions_to_csv
    csv_data = [CourseRevisionsCsvBuilder::CSV_HEADERS + ['course_slug']]
    @campaign.courses.find_each do |course|
      CourseRevisionsCsvBuilder.new(course).revisions_rows.each do |row|
        row_with_slug = row + [course.slug]
        csv_data << row_with_slug
      end
    end

    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  def wikidata_to_csv
    csv_data = [CourseWikidataCsvBuilder::CSV_HEADERS]
    courses = @campaign.courses
                       .joins(:course_stat)
    courses.find_each do |course|
      builder = CourseWikidataCsvBuilder.new(course)
      next unless builder.wikidata_stats?

      csv_data << builder.stat_row
    end

    csv_data << sum_wiki_columns(csv_data) if courses.any?

    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  def sum_wiki_columns(csv_data)
    # Skip 1st header row + 1st column course name
    data_rows = csv_data[1..].transpose[1..]
    return [] if data_rows.nil?
    data_rows.map(&:sum).unshift('Total')
  end

  class AllCourses
    def self.courses
      Course.all
    end
  end
end
