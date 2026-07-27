# frozen_string_literal: true

# Records (or updates) a student's claim-verification exercise response for
# their taken claim, then marks the exercise's training module complete for
# the course. The module has no slides — the in-dashboard form *is* the whole
# exercise — so submission is the completion event: it sets both the module's
# `completed_at` and the per-course `marked_complete` flag that course views
# read.
#
# Answers for steps that don't apply are cleared rather than trusted from the
# client: the verify-the-claim step only exists when the source was accessed,
# and the couldn't-find-the-source notes only when it wasn't.
class RecordVerificationClaimResponse
  attr_reader :response

  def initialize(assignment:, answers:)
    @assignment = assignment
    @answers = answers
    perform
  end

  private

  VERIFY_STEP_FIELDS = %i[verdict claim_location verification_notes].freeze

  def perform
    upsert_response
    complete_exercise_module if @response.persisted? && @response.errors.empty?
  end

  def upsert_response
    # Keyed per claim: resubmitting for the same claim updates in place, while
    # a later response for a different claim is a new record.
    @response = VerificationClaimResponse.find_or_initialize_by(
      user: @assignment.user, course: @assignment.course,
      verification_claim: @assignment.verification_claim
    )
    @response.assign_attributes(applicable_answers)
    @response.save
  end

  def applicable_answers
    answers = @answers.to_h.symbolize_keys
    if answers[:source_access] == 'accessed'
      answers[:source_access_notes] = nil
    else
      VERIFY_STEP_FIELDS.each { |field| answers[field] = nil }
    end
    answers
  end

  # The exercise's module is identified by its launch path, not a hardcoded id.
  def complete_exercise_module
    exercise_modules.each do |training_module|
      tmu = TrainingModulesUsers.create_or_find_by(user: @assignment.user,
                                                   training_module_id: training_module.id)
      tmu.completed_at ||= Time.zone.now
      tmu.mark_completion(true, @assignment.course_id)
      tmu.save
    end
  end

  def exercise_modules
    TrainingModule.all.select { |tm| tm.exercise_path == 'verify_claim' }
  end
end
