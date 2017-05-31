# frozen_string_literal: true

require 'csv'

class CourseCsvBuilder
  def initialize(course)
    @course = course
  end

  CSV_HEADERS = %w[
    course_slug
    title
    institution
    term
    new_or_returning
    editors
    new_editors
    articles_edited
    articles_created
    bytes_added
    total_edits
    mainspace_edits
    article_talk_edits
    userspace_edits
    article_views
    upload_count
    uploads_used_in_articles
    upload_usage_count_across_all_wikis
    training_completion_rate
  ].freeze
  def row
    row = [@course.slug]
    row << @course.title
    row << @course.school
    row << @course.term
    row << new_or_returning_tag
    row << @course.user_count
    row << new_editors_count
    row << @course.article_count
    row << @course.new_article_count
    row << @course.character_sum
    row << @course.revision_count
    row << revisions_by_namespace(Article::Namespaces::MAINSPACE)
    row << revisions_by_namespace(Article::Namespaces::TALK)
    row << revisions_by_namespace(Article::Namespaces::USER)
    row << @course.view_sum
    row << @course.upload_count
    row << @course.uploads_in_use_count
    row << @course.upload_usages_count
    row << training_completion_rate
    row
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    csv_data << row
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  private

  def new_or_returning_tag
    tags = @course.tags.pluck(:tag)
    return 'first_time_instructor' if tags.include?('first_time_instructor')
    return 'returning_instructor' if tags.include?('returning_instructor')
    return 'unknown'
  end

  def new_editors_count
    # A user counts as a new editor if they registered during the course
    @course.students.where(registered_at: @course.start..@course.end).count
  end

  def revisions_by_namespace(namespace)
    @course.revisions.joins(:article).where(articles: { namespace: namespace }).count
  end

  def training_completion_rate
    return if @course.user_count.zero?
    @course.trained_count.to_f / @course.user_count
  end
end
