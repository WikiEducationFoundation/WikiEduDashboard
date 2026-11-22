# frozen_string_literal: true

#= Counts the retained new editors of a course for the per-wiki course CSV.
# Reads the retained_after_course flag recorded by RetainedEditorCheckWorker,
# the same data the system CSV uses, so both CSVs agree. Returns nil while
# retention is still pending, so the CSV shows a blank instead of 0.
class RetainedNewEditorsStats
  def initialize(course)
    @course = course
  end

  def count
    return 0 unless new_editors.exists?
    return nil if pending?

    new_editors.where(retained_after_course: true).count
  end

  private

  def new_editors
    @new_editors ||= CoursesUsers.joins(:course, :user)
                                 .where(course_id: @course.id,
                                        role: CoursesUsers::Roles::STUDENT_ROLE)
                                 .where(NewEditorDateConditions::DURING_PROGRAM)
  end

  # RetainedEditorCheckWorker only checks courses that ended at least 30 days
  # ago, so until every new editor has been checked the count isn't final.
  def pending?
    new_editors.where(retained_after_course_checked_at: nil).exists?
  end
end
