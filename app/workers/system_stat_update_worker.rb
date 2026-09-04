# frozen_string_literal: true

#= SystemStatUpdateWorker
# Enqueued by DailyUpdate after the daily update cycle completes,
# ensuring course caches are fresh before computing the snapshot.
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
      retained_new_editors_count: compute_retained_new_editors_count,
      active_facilitators_count: compute_active_facilitators_count,
      total_characters_added: courses.sum(:character_sum),
      wiki_stats: compute_wiki_stats(courses)
    }
  end

  def compute_retained_new_editors_count
    CoursesUsers
      .joins(:course, :user)
      .where(courses: { private: false },
             role: CoursesUsers::Roles::STUDENT_ROLE,
             retained_after_course: true)
      .where(NewEditorDateConditions::DURING_PROGRAM)
      .distinct
      .count('users.id')
  end

  # New editors (original definition): students who registered their
  # Wikipedia account during the program period (start to end).
  def compute_new_editors_count
    new_editor_base_scope
      .where(NewEditorDateConditions::DURING_PROGRAM)
      .distinct
      .count
  end

  # New editors (WMF definition): includes students who registered up to
  # 60 days before the program start.
  def compute_new_editors_count_with_preregistration
    new_editor_base_scope
      .where(NewEditorDateConditions::WITH_PREREGISTRATION)
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
    editors = compute_new_editors_with_preregistration_by_wiki
    retained = compute_retained_editors_by_wiki
    wikis_by_id = Wiki.where(id: wiki_data.map { |wd| wd[0] }).index_by(&:id)

    wiki_data.each_with_object({}) do |row, stats|
      entry = build_wiki_entry(row, wikis_by_id, editors, retained)
      stats[entry[:domain]] = entry[:data] if entry
    end
  end

  def build_wiki_entry(row, wikis_by_id, editors, retained)
    wiki_id, edits, programs, articles_created = row
    wiki = wikis_by_id[wiki_id]
    return nil unless wiki

    {
      domain: wiki.domain,
      data: {
        'edits' => edits.to_i,
        'programs' => programs.to_i,
        'articles_created' => articles_created.to_i,
        'new_editors_with_preregistration' => editors[wiki_id] || 0,
        'retained_editors' => retained[wiki_id] || 0
      }
    }
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

  def compute_new_editors_with_preregistration_by_wiki
    new_editor_base_scope
      .where(NewEditorDateConditions::WITH_PREREGISTRATION)
      .group('courses.home_wiki_id')
      .distinct
      .count('users.id')
  end

  def compute_retained_editors_by_wiki
    CoursesUsers
      .joins(:course, :user)
      .where(courses: { private: false },
             role: CoursesUsers::Roles::STUDENT_ROLE,
             retained_after_course: true)
      .where(NewEditorDateConditions::DURING_PROGRAM)
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
