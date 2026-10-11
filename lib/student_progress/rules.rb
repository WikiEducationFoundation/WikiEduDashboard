# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/assignment_pipeline"

module StudentProgress
  # What counts as done, for each kind of student work the Dashboard tracks.
  # The Canvas integration and the course page's Assignments tab both read
  # completion through these, so the two can't disagree about whether a student
  # has finished something. Each takes already-loaded records and runs no
  # queries.
  module Rules
    module_function

    # A training-kind module is done once the student reaches its last slide.
    def training_complete?(tmu)
      tmu&.completed_at.present?
    end

    # An exercise is done once the student marks it complete for this course
    # (or an automatic check does it for them, e.g. VerifyExerciseArticle).
    # Rows from before completion was recorded per course keep the flag at the
    # top level; those still count, as they do on the Students tab.
    def exercise_complete?(tmu, course)
      return false if tmu.nil?

      flags = tmu.flags
      (flags[course.id] || flags)[:marked_complete] == true
    end

    def module_complete?(tmu, training_module, course)
      return exercise_complete?(tmu, course) if training_module.exercise?

      training_complete?(tmu)
    end

    # A sandbox page's status says where the page ended up (userspace, draft
    # space, mainspace, elsewhere); for "has the student started this" they all
    # mean yes. The statuses are refreshed by CheckAssignmentStatus rather than
    # checked live, so a page created minutes ago can still read as missing.
    def page_created?(status)
      status != AssignmentPipeline::SandboxStatuses::DOES_NOT_EXIST
    end

    # A peer review is done when the student marks it complete or their review
    # page exists. The two fail in opposite directions: the status is immediate
    # but depends on the student clicking through the steps; the page catches a
    # student who didn't, but trails the work by up to an update cycle.
    def review_complete?(assignment)
      assignment.status == AssignmentPipeline::ReviewStatuses::PEER_REVIEW_COMPLETED ||
        page_created?(assignment.peer_review_sandbox_status)
    end
  end
end
