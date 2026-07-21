# frozen_string_literal: true

# Roster/grade sync status for one LtiCourseBinding, shared by the course
# page's LMS-integration sidebar (LmsIntegrationStatusController) and the
# in-Canvas instructor launch status view — one source so the two surfaces
# can't disagree.
class LtiSyncStatus
  def initialize(binding)
    @binding = binding
  end

  def synced_students_count
    synced_students.size
  end

  # The most recent Canvas sync of any kind. Falls through roster sync →
  # grade sync → the latest student link (a student can link via their own
  # launch before either sync runs), so it never reads "not yet synced"
  # while students are already synced.
  def last_synced_at
    [@binding.last_roster_sync_at, @binding.last_grade_sync_at,
     synced_students.filter_map(&:linked_at).max].compact.max
  end

  def grade_sync_error?
    @binding.last_grade_sync_error.present?
  end

  private

  # Students only — a bound course's instructor also has a linked context,
  # and counting it would report "1 synced student" before anyone signs in.
  def synced_students
    @synced_students ||= @binding.linked_student_contexts
  end
end
