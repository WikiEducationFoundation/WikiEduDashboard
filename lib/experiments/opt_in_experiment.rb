# frozen_string_literal: true

# Base class for opt-in research experiments.
#
# An instructor opts a course in (or out) through a panel in the assignment
# wizard, which records a Tag on the course. Enrolled students of a
# participating course are then individually invited to opt in or out on the
# course page; their choice is stored durably in an ExperimentCoursesUser row.
#
# Opting in performs no action on the student's wiki account. An experiment that
# needs a userscript installed directs the student to install it themselves and
# then confirms it by reading their common.js, which requires no OAuth grant; see
# CheckExperimentUserscript and the `userscript_*` methods on subclasses.
#
# Concrete subclasses define `slug`, `eligible_course?` and
# `student_invitation_copy`. They are registered via the require at the bottom of
# this file, so requiring this file alone is enough to use the registry.
class OptInExperiment
  def self.active
    [Fall2026ResearchExperiment.new]
  end

  def self.find(slug)
    active.find { |experiment| experiment.slug == slug }
  end

  # The active experiment a course is eligible for, if any.
  def self.for_course(course)
    active.find { |experiment| experiment.eligible_course?(course) }
  end

  def slug
    raise NotImplementedError
  end

  def eligible_course?(_course)
    raise NotImplementedError
  end

  # Copy shown in the student-facing invitation modal. Lives here (not in
  # en.yml) so this ephemeral experiment text stays out of the translation
  # pipeline; the controller hands it to the React component. Returns a hash
  # with keys: :title, :message, :consent_form, :opt_in, :opt_out,
  # :install_title, :install_message, :install_button, :install_verify_button,
  # :install_not_found (the :message, :consent_form and :install_message values
  # are Markdown).
  def student_invitation_copy
    raise NotImplementedError
  end

  # Tag key and values recorded by the wizard for the instructor's choice.
  def tag_key
    "#{slug}_optin"
  end

  def opted_in_tag
    "#{slug}_opted_in"
  end

  def opted_out_tag
    "#{slug}_opted_out"
  end

  # A course participates once an eligible course has been tagged opted-in by
  # its instructor through the wizard.
  def course_participating?(course)
    eligible_course?(course) && course.tag?(opted_in_tag)
  end

  # Whether the student-facing side is live yet. An experiment can start
  # collecting instructor opt-ins before students are invited; override in
  # subclasses that need to stage the rollout that way.
  def student_invitations_open?
    true
  end

  # A student may be invited, and may respond, only once their course is
  # participating and the student-facing side is live.
  def open_to_student?(courses_user)
    student_invitations_open? && course_participating?(courses_user.course)
  end

  # Whether this enrolled student still needs to see the invitation.
  def needs_response?(courses_user)
    return false unless open_to_student?(courses_user)
    participation(courses_user).nil?
  end

  def participation(courses_user)
    ExperimentCoursesUser.find_by(experiment_slug: slug, courses_user_id: courses_user.id)
  end

  def handle_student_opt_in(courses_user)
    upsert_participation(courses_user, :opted_in)
  end

  def handle_student_opt_out(courses_user)
    upsert_participation(courses_user, :opted_out)
    :opted_out
  end

  private

  def upsert_participation(courses_user, status)
    record = ExperimentCoursesUser.find_or_initialize_by(
      experiment_slug: slug, courses_user_id: courses_user.id
    )
    record.update!(status:)
    record
  end
end

require_dependency "#{Rails.root}/lib/experiments/fall_2026_research_experiment"
