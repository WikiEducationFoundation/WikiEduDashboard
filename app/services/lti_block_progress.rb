# frozen_string_literal: true

# Computes a single (Block, User) AGS score payload for the LTIAAS grade
# sync. A block scores 1.0/1.0 if every TrainingModule attached to it is
# considered complete for that user; 0.0/1.0 otherwise. v1 considers a
# training-kind module complete when TrainingModulesUsers.completed_at is
# set, and an exercise-kind module complete when
# `flags[course_id][:marked_complete]` is truthy.
#
# The comment field carries:
#   - A "[Late]" marker prefix when the block has a calculated due date in
#     the past and the user has completed it. Score remains 1.0; Wiki Ed
#     practice doesn't auto-penalize late training, but the marker shows
#     up in the gradebook so instructors with their own policy can act.
#   - For each exercise module the user has engaged with, a "<Module>:
#     <sandbox-url>" line so instructors can link straight to the
#     student's bibliography / outline / etc.
#
# `signature` is a stable hash of (score_given, comment) for dedup —
# SyncLtiGrades skips a POST when the LtiLineItem's last_pushed_signature
# matches what we'd push next.
class LtiBlockProgress
  attr_reader :score_given, :score_maximum, :comment

  SCORE_MAXIMUM = 1.0

  def initialize(block, user)
    @block = block
    @user = user
    @course = block.course
    @training_modules = block.training_modules.to_a
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

  private

  def compute_score
    return 0.0 if @training_modules.empty?
    return SCORE_MAXIMUM if @training_modules.all? { |m| module_complete?(m) }

    0.0
  end

  def compute_comment
    parts = []
    parts << '[Late]' if late_completion?
    sandbox_lines.each { |line| parts << line }
    parts.join("\n").presence
  end

  def late_completion?
    return false unless @score_given >= SCORE_MAXIMUM

    due = @block.calculated_due_date
    return false if due.nil?

    Time.zone.today > due
  end

  def sandbox_lines
    @training_modules.select(&:exercise?).filter_map do |mod|
      tmu = TrainingModulesUsers.find_by(user: @user, training_module: mod)
      next unless tmu&.completed_at || tmu&.flags&.dig(@course.id, :marked_complete)
      next unless mod.respond_to?(:sandbox_location) && mod.sandbox_location

      "#{mod.name}: #{sandbox_url_for(tmu)}"
    end
  end

  def module_complete?(mod)
    tmu = TrainingModulesUsers.find_by(user: @user, training_module: mod)
    return false unless tmu

    return tmu.flags.dig(@course.id, :marked_complete) ? true : false if mod.exercise?

    tmu.completed_at.present?
  end

  def sandbox_url_for(tmu)
    "#{@course.home_wiki.base_url}/wiki/#{tmu.exercise_sandbox_location}"
  end
end
