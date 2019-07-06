# frozen_string_literal: true

require 'csv'
require_dependency "#{Rails.root}/lib/analytics/course_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_articles_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_revisions_csv_builder"

class CampaignCsvBuilder
  def initialize(campaign)
    @campaign = campaign || AllCourses
  end

  def courses_to_csv
    csv_data = [CourseCsvBuilder::CSV_HEADERS]
    @campaign.courses.each do |course|
      csv_data << CourseCsvBuilder.new(course).row
    end

    CSV.generate { |csv| csv_data.uniq.each { |line| csv << line } }
  end

  def articles_to_csv
    csv_data = [CourseArticlesCsvBuilder::CSV_HEADERS + ['course_slug']]
    @campaign.courses.each do |course|
      CourseArticlesCsvBuilder.new(course).article_rows.each do |row|
        row_with_slug = row + [course.slug]
        csv_data << row_with_slug
      end
    end

    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  def revisions_to_csv
    csv_data = [CourseRevisionsCsvBuilder::CSV_HEADERS + ['course_slug']]
    @campaign.courses.each do |course|
      CourseRevisionsCsvBuilder.new(course).revisions_rows.each do |row|
        row_with_slug = row + [course.slug]
        csv_data << row_with_slug
      end
    end

    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  class AllCourses
    def self.courses
      Course.all
    end
  end
end
