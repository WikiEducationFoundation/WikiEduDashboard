# frozen_string_literal: true

#= FacilitatorStatUpdateWorker
# Runs weekly via sidekiq-cron (Sunday 2:00 AM UTC).
# Computes per-facilitator metrics using bulk SQL queries (GROUP BY)
# to avoid N+1 queries.
class FacilitatorStatUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'daily_update', lock: :until_executed

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def perform
    return if Features.wiki_ed?

    Rails.logger.info { "FacilitatorStatUpdateWorker: starting for #{Time.zone.today}" }
    metrics = compute_all_metrics
    today = Time.zone.today
    upserted = 0

    records = metrics[:facilitator_ids].map do |user_id|
      build_record(user_id, today, metrics)
    end

    begin
      if records.any?
        records.each_slice(100) do |batch|
          FacilitatorStat.upsert_all(batch)
          upserted += batch.size
        end
      end
    rescue StandardError => e
      Rails.logger.error do
        "FacilitatorStatUpdateWorker: batch upsert failed: #{e.message}"
      end
      raise e
    end

    Rails.logger.info do
      "FacilitatorStatUpdateWorker: finished. upserted=#{upserted}"
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  def compute_all_metrics
    {
      facilitator_ids: all_facilitator_ids,
      program_counts: compute_program_counts,
      active_counts: compute_active_program_counts,
      edit_sums: compute_edit_sums,
      character_sums: compute_character_sums,
      student_counts: compute_student_counts,
      new_editor_counts: compute_new_editor_counts,
      new_editor_counts_with_preregistration: compute_new_editor_counts_with_preregistration,
      active_in_year: compute_active_in_last_year
    }
  end

  def build_record(user_id, today, metrics)
    {
      snapshot_date: today,
      user_id: user_id,
      total_programs_count: metrics[:program_counts][user_id] || 0,
      active_programs_count: metrics[:active_counts][user_id] || 0,
      total_edits: metrics[:edit_sums][user_id] || 0,
      new_editors_count: metrics[:new_editor_counts][user_id] || 0,
      new_editors_count_with_preregistration:
        metrics[:new_editor_counts_with_preregistration][user_id] || 0,
      total_students_count: metrics[:student_counts][user_id] || 0,
      total_characters_added: metrics[:character_sums][user_id] || 0,
      active_in_last_year: metrics[:active_in_year].include?(user_id)
    }
  end

  # All unique facilitator user_ids from non-private courses
  def all_facilitator_ids
    instructor_scope.distinct.pluck(:user_id)
  end

  # Total programs per facilitator (all time)
  def compute_program_counts
    instructor_scope.group(:user_id).count
  end

  # Active programs per facilitator (strictly current)
  def compute_active_program_counts
    instructor_scope
      .merge(Course.strictly_current)
      .group(:user_id)
      .count
  end

  # Total edits across all programs per facilitator
  def compute_edit_sums
    instructor_scope
      .group(:user_id)
      .sum('courses.revision_count')
  end

  # Total characters added across all programs per facilitator
  def compute_character_sums
    instructor_scope
      .group(:user_id)
      .sum('courses.character_sum')
  end

  # Total distinct students per facilitator (single query via join)
  def compute_student_counts
    student_instructor_join
      .group('instructor_cu.user_id')
      .count(Arel.sql('DISTINCT users.id'))
  end

  # New editors per facilitator (registered during program)
  def compute_new_editor_counts
    student_instructor_join
      .where('users.registered_at BETWEEN courses.start AND courses.end')
      .group('instructor_cu.user_id')
      .count(Arel.sql('DISTINCT users.id'))
  end

  # New editors per facilitator (registered with 60-day pre-window)
  def compute_new_editor_counts_with_preregistration
    student_instructor_join
      .where('users.registered_at BETWEEN DATE_SUB(courses.start, INTERVAL 60 DAY) AND courses.end')
      .group('instructor_cu.user_id')
      .count(Arel.sql('DISTINCT users.id'))
  end

  # Facilitators who had a program end within the last 12 months
  def compute_active_in_last_year
    instructor_scope
      .where('courses.end > ?', 1.year.ago)
      .distinct
      .pluck(:user_id)
      .to_set
  end

  # Base scope: instructors in non-private courses
  def instructor_scope
    CoursesUsers
      .joins(:course)
      .where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      .merge(Course.nonprivate)
  end

  # Base join for student/new-editor counting per facilitator.
  # Students are the base (users table), instructors are joined via alias.
  # Produces a single GROUP BY query instead of N+1 per-facilitator loops.
  def student_instructor_join
    User.joins(courses_users: :course)
        .joins(
          "INNER JOIN courses_users instructor_cu " \
          "ON instructor_cu.course_id = courses.id " \
          "AND instructor_cu.role = #{CoursesUsers::Roles::INSTRUCTOR_ROLE}"
        )
        .where(courses_users: { role: CoursesUsers::Roles::STUDENT_ROLE })
        .merge(Course.nonprivate)
  end


end
