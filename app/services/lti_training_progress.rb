# frozen_string_literal: true

# Computes the rolled-up "Wikipedia trainings" progress for one (Course,
# User) — used by the lumped-mode TrainingProgress sentinel line item.
#
# `score_given` is the fraction of training-kind modules in the course's
# timeline that the user has completed (`TrainingModulesUsers.completed_at`
# present), in the range [0.0, 1.0]. Exercise-kind modules are deliberately
# excluded — they get their own per-block line items in lumped mode.
#
# `comment` summarizes "X of Y trainings completed" for instructor
# legibility in the Canvas gradebook.
class LtiTrainingProgress
  attr_reader :score_given, :score_maximum, :comment

  SCORE_MAXIMUM = 1.0

  def initialize(course, user)
    @course = course
    @user = user
    @training_modules = collect_training_modules
    @score_maximum = SCORE_MAXIMUM
    @score_given = compute_score
    @comment = compute_comment
  end

  def signature
    @signature ||= Digest::SHA1.hexdigest("#{@score_given}|#{@comment}")
  end

  def gradable?
    @training_modules.any?
  end

  # Exposed (alongside the derived score/comment) for the in-Canvas
  # assignment view of the roll-up column, which shows "X of Y" per student.
  def total_count
    @training_modules.size
  end

  def completed_count
    @completed_count ||= @training_modules.count do |mod|
      tmu = TrainingModulesUsers.find_by(user: @user, training_module: mod)
      tmu&.completed_at.present?
    end
  end

  private

  def collect_training_modules
    module_ids = @course.blocks.flat_map(&:training_module_ids).uniq
    TrainingModule.where(id: module_ids).to_a
                  .reject(&:exercise?)
  end

  def compute_score
    return 0.0 if @training_modules.empty?

    completed_count.to_f / total_count
  end

  def compute_comment
    return nil if @training_modules.empty?

    "#{completed_count} of #{total_count} trainings completed"
  end
end
