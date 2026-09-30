# frozen_string_literal: true

# == Schema Information
#
# Table name: verification_claim_assignments
#
#  id                    :bigint           not null, primary key
#  user_id               :integer          not null
#  course_id             :integer          not null
#  verification_claim_id :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

# Records the pooled VerificationClaim a student in a course is currently
# working on. This is assignment only: the verification work itself is
# submitted as a VerificationClaimResponse (keyed per claim). The assignment
# is a re-pointable "current claim" cursor — one row per student per course —
# so it puts no limit on how many claims a student responds to over time.
class VerificationClaimAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :verification_claim

  validates :user_id, uniqueness: { scope: :course_id }
end
