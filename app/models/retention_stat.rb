# frozen_string_literal: true
# == Schema Information
#
# Table name: retention_stats
#
#  id                   :bigint           not null, primary key
#  course_id            :integer          not null
#  user_id              :integer          not null
#  sessions_during      :integer          default(0), not null
#  days_to_return       :integer
#  sessions_after       :integer
#  edits_60_90          :integer
#  prior_edit_count     :integer          default(0), not null
#  long_term_wikipedian :boolean          default(FALSE), not null
#  prior_course_count   :integer          default(0), not null
#  computed_at          :datetime         not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

require_dependency "#{Rails.root}/lib/analytics/retention_student_stats"

# One student's retention metrics for one Scholars & Scientists course, as
# computed by RetentionStudentStats and stored by UpdateCourseRetentionStats.
# The report card (RetentionReportCard) is built from these rows.
#
# A post-course metric is nil until its window has closed. `computed_at` records
# when the row was computed, which is what says which windows had closed by then.
class RetentionStat < ApplicationRecord
  belongs_to :course
  belongs_to :user

  validates :user_id, uniqueness: { scope: :course_id }

  # Whether the course's rows lag behind what can be computed now: a metric
  # window has closed since they were computed, or they no longer match the
  # roster (which is also what makes a course with students and no rows due, and
  # a course with neither not due). Nothing is due before the first checkpoint,
  # a day after the course ends.
  def self.update_due?(course, now: Time.zone.now)
    current_stage = RetentionStudentStats.stage(course, now)
    return false if current_stage.zero?

    rows = where(course_id: course.id)
    computed_at = rows.minimum(:computed_at)
    return true if computed_at && RetentionStudentStats.stage(course, computed_at) < current_stage

    rows.pluck(:user_id).sort != course.students.pluck(:id).sort
  end

  # Had already taken an earlier course when this one began.
  def returning?
    prior_course_count.positive?
  end
end
