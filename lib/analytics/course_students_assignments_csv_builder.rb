# frozen_string_literal: true

require 'csv'

class CourseStudentsAssignmentsCsvBuilder
  def initialize(course)
    @course = course
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    
    # Get all students in the course
    students = @course.courses_users
                     .where(role: CoursesUsers::Roles::STUDENT_ROLE)
                     .includes(:user)
    
    students.each do |courses_user|
      # Get all assignments for this student
      assignments = @course.assignments
                          .where(user: courses_user.user)
                          .includes(:article)
      
      # Separate assigned (editing) and reviewing assignments
      assigned_articles = assignments.where(role: Assignment::Roles::ASSIGNED_ROLE)
      reviewing_articles = assignments.where(role: Assignment::Roles::REVIEWING_ROLE)
      
      # Get student's real name, preferring courses_users.real_name over users.real_name
      real_name = courses_user.real_name.presence || courses_user.user.real_name
      formatted_name = format_real_name(real_name)
      
      # If no assignments, create one row with empty assignments
      if assigned_articles.empty? && reviewing_articles.empty?
        csv_data << [
          formatted_name,
          courses_user.user.username,
          '',
          ''
        ]
      else
        # Create rows for each assignment combination
        create_assignment_rows(csv_data, formatted_name, courses_user.user.username, 
                              assigned_articles, reviewing_articles)
      end
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

  def format_real_name(real_name)
    return '' if real_name.blank?
    
    # Split by common separators and clean up
    parts = real_name.split(/[,;]/).map(&:strip)
    return real_name if parts.length == 1
    
    # If we have multiple parts, assume first is surname, rest are given names
    surname = parts.first
    given_names = parts[1..-1].join(' ')
    
    "#{surname}, #{given_names}"
  end

  def create_assignment_rows(csv_data, real_name, username, assigned_articles, reviewing_articles)
    # Create a row for each assigned article, pairing with reviewing articles
    if assigned_articles.any?
      assigned_articles.each_with_index do |assigned_article, index|
        # Pair with corresponding reviewing article if available
        reviewing_article = reviewing_articles[index]&.article_title
        
        csv_data << [
          real_name,
          username,
          assigned_article.article_title,
          reviewing_article || ''
        ]
      end
      
      # Add any remaining reviewing articles as separate rows
      if reviewing_articles.count > assigned_articles.count
        reviewing_articles[assigned_articles.count..-1].each do |reviewing_article|
          csv_data << [
            real_name,
            username,
            '',
            reviewing_article.article_title
          ]
        end
      end
    elsif reviewing_articles.any?
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
end

