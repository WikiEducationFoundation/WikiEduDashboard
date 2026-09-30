# frozen_string_literal: true

# == Schema Information
#
# Table name: verification_claim_responses
#
#  id                    :bigint           not null, primary key
#  user_id               :integer          not null
#  course_id             :integer          not null
#  verification_claim_id :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  answers               :text(65535)
#

require_dependency "#{Rails.root}/lib/claim_verification/exercise_form"

# A student's submitted answers for the fact-verification exercise, done entirely
# in the dashboard (the exercise no longer hands off to a sandbox). Keyed per
# claim — one response per claim a student takes on, resubmittable —
# deliberately NOT one per student per course, so the exercise can grow to
# verifying multiple claims.
#
# The answers are one serialized hash keyed by question id, not a column per
# question, so refining the exercise doesn't touch the database. Which questions
# exist and what each accepts is declared in
# config/claim_verification_exercise.yml; this model enforces that declaration
# rather than restating it.
class VerificationClaimResponse < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :verification_claim

  serialize :answers, type: Hash

  validates :user_id, uniqueness: { scope: %i[course_id verification_claim_id] }
  validate :answers_are_what_the_exercise_asked

  # One question's answer, or nil where the exercise didn't ask it (an
  # unanswered optional question, or a step the student's path skipped).
  def answer(question_id)
    answers[question_id.to_s]
  end

  private

  def answers_are_what_the_exercise_asked
    ClaimVerification::ExerciseForm.new.errors_in(answers).each do |message|
      errors.add(:answers, message)
    end
  end
end
