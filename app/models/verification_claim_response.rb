# frozen_string_literal: true

# == Schema Information
#
# Table name: verification_claim_responses
#
#  id                    :bigint           not null, primary key
#  user_id               :integer          not null
#  course_id             :integer          not null
#  verification_claim_id :integer          not null
#  source_access         :string(255)      not null
#  source_access_notes   :text(65535)
#  verdict               :string(255)
#  claim_location        :text(65535)
#  verification_notes    :text(65535)
#  other_comments        :text(65535)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

# A student's submitted answers for the claim-verification exercise: whether
# they could access the cited source, how well it backs up their taken claim,
# and their free-response notes. Done entirely in the dashboard (the exercise
# no longer hands off to a sandbox). Keyed per claim — one response per claim
# a student takes on, resubmittable — deliberately NOT one per student per
# course, so the exercise can grow to verifying multiple claims.
class VerificationClaimResponse < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :verification_claim

  # "Were you able to access the full text of the cited source for your claim?"
  SOURCE_ACCESS_VALUES = %w[
    accessed
    nonexistent
    inaccessible
  ].freeze

  # "Does the source back up the claim?" — asked only when the source was accessed.
  VERDICT_VALUES = %w[
    full_support
    mostly_supports
    partial_support
    mostly_unsupported
    unsupported
    contradicted
    undetermined
  ].freeze

  validates :user_id, uniqueness: { scope: %i[course_id verification_claim_id] }
  validates :source_access, inclusion: { in: SOURCE_ACCESS_VALUES }
  # The verdict (and the rest of the verify-the-claim step) only makes sense
  # when the student had the source in hand.
  validates :verdict, inclusion: { in: VERDICT_VALUES }, if: :source_accessed?
  validates :verdict, absence: true, unless: :source_accessed?

  def source_accessed?
    source_access == 'accessed'
  end
end
