# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_score_signatures
#
#  id                :integer          not null, primary key
#  lti_line_item_id  :integer          not null
#  lti_context_id    :integer          not null
#  signature         :string(255)      not null
#  last_pushed_at    :datetime         not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

# Per-(line item, student) score POST dedup record. The signature is the
# SHA1 hash produced by LtiBlockProgress / LtiTrainingProgress over the
# (score_given, comment) tuple that would be pushed; SyncLtiGrades skips
# the LTIAAS POST whenever the stored signature matches the next one to
# push, so the 30-min cron only emits POSTs for state changes.
class LtiScoreSignature < ApplicationRecord
  belongs_to :lti_line_item
  belongs_to :lti_context

  validates :signature, :last_pushed_at, presence: true
  validates :lti_context_id, uniqueness: { scope: :lti_line_item_id }
end
