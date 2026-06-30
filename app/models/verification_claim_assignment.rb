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

# Records that a student in a course has been assigned one pooled
# VerificationClaim to verify against its source. This is assignment only:
# the student does the verification in their Wikipedia sandbox, and nothing
# they produce is stored here. One assignment per student per course.
class VerificationClaimAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :verification_claim

  validates :user_id, uniqueness: { scope: :course_id }
end
