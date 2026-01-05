# frozen_string_literal: true

require 'csv'
require_dependency "#{Rails.root}/lib/analytics/course_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_articles_csv_builder"
require "#{Rails.root}/lib/analytics/course_wikidata_csv_builder"

class CampaignCsvBuilder
  def initialize(campaign)
    @campaign = campaign || AllCourses
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def courses_to_csv
    csv_data = [CourseCsvBuilder::CSV_HEADERS]

    preload_course_data if @campaign.courses.size > 1

    @campaign.courses.find_each do |course|
      csv_data << CourseCsvBuilder.new(
        course,
        tag: tags[course.id]&.first&.tag || 'unknown',
        revision: revision_counts.select { |(id, _), _| id == course.id },
        new_editors: new_editor_counts[course.id] || 0,
        home_wiki: home_wiki_url(course)
      ).row
    end

    CSV.generate { |csv| csv_data.uniq.each { |line| csv << line } }
  end

  def preload_course_data
    course_ids
    tags
    revision_counts
    new_editor_counts
    wikis
  end

  def course_ids
    return @course_ids if @course_ids

    @course_ids = @campaign.courses.pluck(:id)
  end

  def tags
    return @tags if @tags

    @tags = Tag
            .where(course_id: @course_ids, tag: %w[first_time_instructor returning_instructor])
            .select(:tag, :course_id)
            .group_by(&:course_id)
  end

  def revision_counts
    return @revision_counts if @revision_counts

    @revision_counts = ArticleCourseTimeslice
                       .where(tracked: true, course_id: @course_ids)
                       .select(:revision_count, :course_id)
                       .joins(:article)
                       .where(articles: { namespace: [0, 1, 2] })
                       .group(:course_id, :namespace)
                       .sum(:revision_count)
  end

  def new_editor_counts
    return @new_editor_counts if @new_editor_counts

    @new_editor_counts = User
                         .where(registered_at: @campaign.courses.minimum(:start)..@campaign.courses.maximum(:end)) # rubocop:disable Layout/LineLength
                         .joins(:courses_users)
                         .where(courses_users: { course_id: @course_ids, role: CoursesUsers::Roles::STUDENT_ROLE }) # rubocop: disable Layout/LineLength
                         .group(:course_id)
                         .count
  end

  def wikis
    return @wikis if @wikis

    @wikis = Wiki.where(id: @campaign.courses.pluck(:home_wiki_id)).group_by(&:id)
  end

  def home_wiki_url(course)
    wiki = wikis[course.home_wiki_id]&.first
    return '' unless wiki

    language = wiki.language
    project = wiki.project

    if language && project
      "#{language}.#{project}.org"
    else
      Wiki::MULTILINGUAL_PROJECTS[project]
    end
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
