# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/tag_manager"

# This handles course submissions for new instructors
# for our Fall 2024 test of "no sandbox" vs traditional sandbox drafting.
# The first course from a new instructor will get randomly assigned to
# the experimental condition or the control, until we reach the target
# number of experiment courses.
class NoSandboxesFall2024Experiment
  EXPERIMENT_TAG = 'no_sandbox_fall_2024_experiment_condition'
  CONTROL_TAG = 'no_sandbox_fall_2024_control_condition'
  TAG_KEY = 'no_sandbox_fall_2024_experiment'
  TARGET_NEW_INSTRUCTOR_COUNT = 50

  def self.experiment_courses
    Tag.courses_tagged_with EXPERIMENT_TAG
  end

  def self.control_courses
    Tag.courses_tagged_with CONTROL_TAG
  end

  def initialize(course, creator)
    return unless Features.wiki_ed?

    unless Setting.exists?(key: 'no_sandbox_fall_2024_experiment')
      Setting.create(key: 'no_sandbox_fall_2024_experiment',
                     value: { experiment_condition_count: 0 })
    end
    @experiment_setting = Setting.find_by(key: 'no_sandbox_fall_2024_experiment')
    @course = course
    @creator = creator
    process_course
  end

  private

  def process_course
    # screen for eligibility
    return unless eligible?

    # handle not-first course from new instructor
    handle_multiple_courses { return }

    # check current number of experiment condition instructors
    return if enough_already?

    # choose randomly
    coin_flip = [true, false].sample

    # add tag and flag if selected
    if coin_flip
      mark_course_for_experiment
      @experiment_setting.value[:experiment_condition_count] += 1
      @experiment_setting.save!
    else
      mark_course_for_control
    end
  end

  def eligible?
    # screen out courses that weren't persisted
    return false unless @course.persisted?
    # Only courses happening in Fall 2024
    return false unless @course.start > '2024-06-01'.to_date
    return false unless @course.start < '2024-11-01'.to_date
    # Only first-time instructors
    return false if @creator.returning_instructor?

    true
  end

  # If another course from the same new instructor is already in the experiment
  # we put this course into the same condition.
  def handle_multiple_courses
    if (@creator.courses & NoSandboxesFall2024Experiment.experiment_courses).any?
      mark_course_for_experiment
      yield
    elsif (@creator.courses & NoSandboxesFall2024Experiment.control_courses).any?
      mark_course_for_control
      yield
    end
  end

  def enough_already?
    @experiment_setting.value[:experiment_condition_count] >= TARGET_NEW_INSTRUCTOR_COUNT
  end

  def mark_course_for_experiment
    TagManager.new(@course).add(tag: EXPERIMENT_TAG, key: TAG_KEY)
    @course.add_flag(key: :no_sandboxes)
  end

  def mark_course_for_control
    TagManager.new(@course).add(tag: CONTROL_TAG, key: TAG_KEY)
  end
end
