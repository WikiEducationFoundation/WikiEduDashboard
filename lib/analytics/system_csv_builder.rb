# frozen_string_literal: true

require 'csv'
require_dependency "#{Rails.root}/lib/analytics/course_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/system_csv_filter_validator"

# Generates system-wide CSV exports with dynamic filter support.
# This is a standalone builder designed for admin-only, async exports
# across all non-private programs. It uses find_each for memory-safe
# batching and preloads associated data in bulk.
#
# Filters supported:
#   campaign_slug  — Courses belonging to a specific campaign
#   start_date     — Courses starting on or after this date
#   end_date       — Courses ending on or before this date
#   wiki_domain    — Courses with a specific home wiki (e.g. 'en.wikipedia.org')
#   course_type    — Courses of a specific STI type (e.g. 'Editathon')
#   status         — 'active' (current_and_future) or 'archived'
#
# Usage:
#   SystemCsvBuilder.new(filters: { status: 'active' }).generate_csv
#
class SystemCsvBuilder
  VALID_COURSE_TYPES = SystemCsvFilterValidator::VALID_COURSE_TYPES
  VALID_STATUSES = SystemCsvFilterValidator::VALID_STATUSES

  def initialize(filters: {})
    @filters = filters
  end

  def generate_csv
    csv_data = [CourseCsvBuilder::CSV_HEADERS]
    preload_course_data

    filtered_courses.find_each do |course|
      csv_data << CourseCsvBuilder.new(
        course,
        tag: tags[course.id]&.first&.tag || 'unknown',
        revision: revision_counts,
        new_editors: new_editor_counts[course.id] || 0,
        home_wiki: home_wiki_url(course)
      ).row
    end

    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  # Returns the filtered course scope. Public so it can be tested directly.
  def filtered_courses
    @filtered_courses ||= build_filtered_scope
  end

  private

  # ————————————————————————————————
  # Scope & filter construction
  # ————————————————————————————————

  def base_scope
    Course.nonprivate
  end

  def build_filtered_scope
    scope = base_scope
    scope = apply_campaign_filter(scope)
    scope = apply_date_filters(scope)
    scope = apply_wiki_filter(scope)
    scope = apply_type_filter(scope)
    scope = apply_status_filter(scope)
    scope.distinct
  end

  def apply_campaign_filter(scope)
    return scope unless @filters[:campaign_slug].present?
    scope.joins(:campaigns).where(campaigns: { slug: @filters[:campaign_slug] })
  end

  def apply_date_filters(scope)
    if @filters[:start_date].present?
      scope = scope.where('courses.start >= ?',
                          @filters[:start_date].to_date)
    end
    if @filters[:end_date].present?
      scope = scope.where('courses.end <= ?',
                          @filters[:end_date].to_date)
    end
    scope
  end

  def apply_wiki_filter(scope)
    return scope unless @filters[:wiki_domain].present?
    wiki_language, wiki_project = parse_wiki_domain(@filters[:wiki_domain])
    scope.joins(:home_wiki).where(wikis: { language: wiki_language, project: wiki_project })
  end

  def apply_type_filter(scope)
    return scope unless @filters[:course_type].present?
    scope.where(type: @filters[:course_type])
  end

  def apply_status_filter(scope)
    case @filters[:status]
    when 'active'
      scope.where('courses.end > ?', Time.zone.now - Course::UPDATE_LENGTH)
    when 'archived'
      scope.where('courses.end <= ?', Time.zone.now - Course::UPDATE_LENGTH)
    else scope
    end
  end

  # Parses a wiki domain string into [language, project] for DB queries.
  # 'en.wikipedia.org'   → ['en', 'wikipedia']
  # 'www.wikidata.org'   → [nil, 'wikidata']
  # 'wikisource.org'     → [nil, 'wikisource']
  def parse_wiki_domain(domain)
    Wiki::MULTILINGUAL_PROJECTS.each do |project, ml_domain|
      return [nil, project] if domain == ml_domain
    end
    parts = domain.split('.')
    return [parts[0], parts[1]] if parts.length >= 3
    [nil, parts[0]]
  end

  # ————————————————————————————————
  # Batched preloading (mirrors CampaignCsvBuilder pattern)
  # ————————————————————————————————

  def preload_course_data
    return if course_ids.empty?

    tags
    revision_counts
    new_editor_counts
    wikis
  end

  def course_ids
    @course_ids ||= filtered_courses.pluck(:id)
  end

  def tags
    @tags ||= begin
      return {} if course_ids.empty?

      Tag
        .where(course_id: course_ids, tag: %w[first_time_instructor returning_instructor])
        .select(:tag, :course_id)
        .group_by(&:course_id)
    end
  end

  def revision_counts
    @revision_counts ||= begin
      return {} if course_ids.empty?

      namespaces = [
        Article::Namespaces::MAINSPACE,
        Article::Namespaces::TALK,
        Article::Namespaces::USER
      ]
      ArticleCourseTimeslice
        .where(tracked: true, course_id: course_ids)
        .select(:revision_count, :course_id)
        .joins(:article)
        .where(articles: { namespace: namespaces })
        .group(:course_id, :namespace)
        .sum(:revision_count)
    end
  end

  def new_editor_counts
    @new_editor_counts ||= begin
      return {} if course_ids.empty?

      min_start = filtered_courses.minimum(:start)
      max_end = filtered_courses.maximum(:end)
      return {} unless min_start && max_end

      User
        .where(registered_at: min_start..max_end)
        .joins(:courses_users)
        .where(courses_users: { course_id: course_ids, role: CoursesUsers::Roles::STUDENT_ROLE })
        .group(:course_id)
        .count
    end
  end

  def wikis
    @wikis ||= begin
      return {} if course_ids.empty?

      Wiki.where(id: filtered_courses.pluck(:home_wiki_id)).group_by(&:id)
    end
  end

  def home_wiki_url(course)
    wikis[course.home_wiki_id]&.first&.domain || ''
  end
end
