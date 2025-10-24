# frozen_string_literal: true

require 'csv'

class CourseStudentsAssignmentsCsvBuilder
  def initialize(course)
    @course = course
  end

  def generate_csv
    csv_data = [CSV_HEADERS]

    # Eager load all assignments for all students to avoid N+1 queries
    student_assignments_map = preload_student_assignments

    students.each do |courses_user|
      process_student_assignments(csv_data, courses_user, student_assignments_map)
    end

    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  private

  CSV_HEADERS = %w[
    real_name
    username
    assigned_article_title
    peer_review_article_title
  ].freeze

  def students
    @course.courses_users
           .where(role: CoursesUsers::Roles::STUDENT_ROLE)
           .includes(:user)
  end

  def preload_student_assignments
    # Fetch all assignments for all students in a single query
    student_user_ids = students.pluck(:user_id)
    assignments = @course.assignments
                         .where(user_id: student_user_ids)
                         .includes(:article)

    # Group assignments by user_id for O(1) lookup
    assignments.group_by(&:user_id)
  end

  def process_student_assignments(csv_data, courses_user, student_assignments_map)
    assignments = student_assignments_map[courses_user.user_id] || []
    assigned_articles = assignments.select { |a| a.role == Assignment::Roles::ASSIGNED_ROLE }
    reviewing_articles = assignments.select { |a| a.role == Assignment::Roles::REVIEWING_ROLE }

    real_name = courses_user.real_name.presence || courses_user.user.real_name
    formatted_name = format_real_name(real_name)

    if assigned_articles.empty? && reviewing_articles.empty?
      csv_data << [
        formatted_name,
        courses_user.user.username,
        '',
        ''
      ]
    else
      create_assignment_rows(csv_data, formatted_name, courses_user.user.username,
                             assigned_articles, reviewing_articles)
    end
  end

  def format_real_name(real_name)
    return '' if real_name.blank?

    # Split by common separators and clean up
    parts = real_name.split(/[,;]/).map(&:strip)
    return real_name if parts.length == 1

    # If we have multiple parts, assume first is surname, rest are given names
    surname = parts.first
    given_names = parts[1..].join(' ')

    "#{surname}, #{given_names}"
  end

  def create_assignment_rows(csv_data, real_name, username, assigned_articles, reviewing_articles)
    # Create a row for each assigned article, pairing with reviewing articles
    if assigned_articles.any?
      create_assigned_article_rows(csv_data, real_name, username,
                                   assigned_articles, reviewing_articles)
    elsif reviewing_articles.any?
      create_reviewing_article_rows(csv_data, real_name, username, reviewing_articles)
    end
  end

  def create_assigned_article_rows(csv_data, real_name, username,
                                   assigned_articles, reviewing_articles)
    process_assigned_articles(csv_data, real_name, username,
                              assigned_articles, reviewing_articles)
    add_remaining_reviewing_articles(csv_data, real_name, username,
                                     assigned_articles, reviewing_articles)
  end

  def process_assigned_articles(csv_data, real_name, username,
                                assigned_articles, reviewing_articles)
    assigned_articles.each_with_index do |assigned_article, index|
      reviewing_article = reviewing_articles[index]&.article_title
      csv_data << [
        real_name,
        username,
        assigned_article.article_title,
        reviewing_article || ''
      ]
    end
  end

  def add_remaining_reviewing_articles(csv_data, real_name, username,
                                       assigned_articles, reviewing_articles)
    return unless reviewing_articles.count > assigned_articles.count

    reviewing_articles[assigned_articles.count..].each do |reviewing_article|
      csv_data << [
        real_name,
        username,
        '',
        reviewing_article.article_title
      ]
    end
  end

  def create_reviewing_article_rows(csv_data, real_name, username, reviewing_articles)
    # If only reviewing articles, create rows for each
    reviewing_articles.each do |reviewing_article|
      csv_data << [
        real_name,
        username,
        '',
        reviewing_article.article_title
      ]
    end
  end
end
