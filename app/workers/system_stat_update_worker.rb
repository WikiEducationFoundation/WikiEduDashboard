# frozen_string_literal: true

require_dependency 'stat_update_helper'

#= SystemStatUpdateWorker
# Runs daily via sidekiq-cron (1 hour after DailyUpdateWorker).
# Computes system-wide metrics across all non-private programs
# and upserts a single row into the system_stats table for today.
class SystemStatUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'daily_update', lock: :until_executed

  def perform
    snapshot_date = Time.zone.today
    Rails.logger.info { "SystemStatUpdateWorker: computing stats for #{snapshot_date}" }

    stats = compute_stats
    SystemStat.upsert(
      stats.merge(snapshot_date: snapshot_date)
    )

    Rails.logger.info { "SystemStatUpdateWorker: upserted snapshot for #{snapshot_date}" }
  end

  private

  def compute_stats
    courses = Course.nonprivate

    {
      total_edits: courses.sum(:revision_count),
      total_article_views: courses.sum(:view_sum),
      total_articles_improved: courses.sum(:article_count),
      total_articles_created: courses.sum(:new_article_count),
      active_programs_count: courses.strictly_current.count,
      archived_programs_count: courses.archived.count,
      new_editors_count: compute_new_editors_count,
      new_editors_count_with_preregistration: compute_new_editors_count_with_preregistration,
      active_facilitators_count: compute_active_facilitators_count,
      total_characters_added: courses.sum(:character_sum),
      wiki_stats: compute_wiki_stats(courses)
    }
  end

  # New editors (original definition): students who registered their
  # Wikipedia account during the program period (start to end).
  def compute_new_editors_count
    new_editor_base_scope
      .where(StatUpdateHelper.new_editor_date_condition(prereg: false))
      .distinct
      .count
  end

  # New editors (WMF definition): includes students who registered up to
  # 60 days before the program start.
  def compute_new_editors_count_with_preregistration
    new_editor_base_scope
      .where(StatUpdateHelper.new_editor_date_condition(prereg: true))
      .distinct
      .count
  end

  # Active facilitators: unique instructors with at least one
  # currently running program (today between start and end).
  def compute_active_facilitators_count
    CoursesUsers
      .joins(:course)
      .where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      .merge(Course.nonprivate.strictly_current)
      .distinct
      .count(:user_id)
  end

  # Per-wiki breakdown: edits, program count, articles created,
  # and new editors grouped by home_wiki_id.
  # Uses string keys for consistent serialization round-tripping.
  def compute_wiki_stats(courses)
    wiki_data = fetch_wiki_aggregates(courses)
    new_editors_by_wiki = compute_new_editors_by_wiki

    wiki_stats = {}
    wiki_data.each do |wiki_id, edits, programs, articles_created|
      wiki = Wiki.find_by(id: wiki_id)
      next unless wiki

      wiki_stats[wiki.domain] = {
        'edits' => edits.to_i,
        'programs' => programs.to_i,
        'articles_created' => articles_created.to_i,
        'new_editors' => new_editors_by_wiki[wiki_id] || 0
      }
    end
    wiki_stats
  end

  def fetch_wiki_aggregates(courses)
    courses.group(:home_wiki_id)
           .pluck(
             :home_wiki_id,
             Arel.sql('SUM(courses.revision_count)'),
             Arel.sql('COUNT(*)'),
             Arel.sql('SUM(courses.new_article_count)')
           )
  end

  def compute_new_editors_by_wiki
    new_editor_base_scope
      .where(StatUpdateHelper.new_editor_date_condition(prereg: true))
      .group('courses.home_wiki_id')
      .distinct
      .count('users.id')
  end

  # Base scope for new editor queries: students in non-private courses.
  def new_editor_base_scope
    User.joins(courses_users: :course)
        .where(courses: { private: false },
               courses_users: { role: CoursesUsers::Roles::STUDENT_ROLE })
  end


end
