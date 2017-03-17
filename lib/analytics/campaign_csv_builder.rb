# frozen_string_literal: true
require 'csv'

class CampaignCsvBuilder
  def initialize(campaign)
    @campaign = campaign
  end

  COURSE_CSV_HEADERS = %w(
    course_slug
    title
    institution
    new_or_returning
    student_count
    articles_edited
    articles_created
    bytes_added
    edit_count
    article_views
    upload_count
    training_completion_rate
  ).freeze
  def courses_to_csv
    csv_data = [COURSE_CSV_HEADERS]
    @campaign.courses.each do |course|
      csv_data << course_row(course)
    end

    CSV.generate { |csv| csv_data.uniq.each { |line| csv << line } }
  end

  private

  def course_row(course)
    row = [course.slug]
    row << course.title
    row << course.school
    row << new_or_returning_tag(course)
    row << course.user_count
    row << course.article_count
    row << course.new_article_count
    row << course.character_sum
    row << course.revision_count
    row << course.view_sum
    row << course.upload_count
    row << training_completion_rate(course)
    row
  end

  def training_completion_rate(course)
    return if course.user_count.zero?
    course.trained_count.to_f / course.user_count
  end

  def new_or_returning_tag(course)
    tags = course.tags.pluck(:tag)
    return 'first_time_instructor' if tags.include?('first_time_instructor')
    return 'returning_instructor' if tags.include?('returning_instructor')
    return 'unknown'
  end
end
