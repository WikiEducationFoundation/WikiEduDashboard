# frozen_string_literal: true
# == Schema Information
#
# Table name: article_audit_finding_feedbacks
#
#  id                            :bigint           not null, primary key
#  article_audit_check_result_id :bigint           not null
#  finding_index                 :integer          not null
#  user_id                       :bigint           not null
#  accurate                      :string(255)
#  accurate_comment              :text(65535)
#  show_to_participants          :string(255)
#  show_to_participants_comment  :text(65535)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#

# One user's evaluation of one Article Audit finding: is it accurate, and
# should it be shown to program participants. Collected to decide which kinds
# of finding are worth showing by default. A finding is its check result plus
# its index in that result's findings; see SummarizeArticleAuditFeedback for
# how responses are tallied.
class ArticleAuditFindingFeedback < ApplicationRecord
  belongs_to :check_result, class_name: 'ArticleAuditCheckResult',
                            foreign_key: :article_audit_check_result_id,
                            inverse_of: :finding_feedbacks
  belongs_to :user

  ACCURATE_OPTIONS = %w[yes partly no].freeze
  SHOW_OPTIONS = %w[yes maybe no].freeze
  # The fields a user fills in, and that the report sends back to them.
  FIELDS = %w[accurate accurate_comment show_to_participants show_to_participants_comment].freeze

  validates :accurate, inclusion: { in: ACCURATE_OPTIONS }, allow_nil: true
  validates :show_to_participants, inclusion: { in: SHOW_OPTIONS }, allow_nil: true
  validates :finding_index, uniqueness: { scope: %i[article_audit_check_result_id user_id] }
  validate :finding_exists

  # The report's id for the finding (see ArticleAuditReportPresenter).
  def finding_id
    "#{article_audit_check_result_id}-#{finding_index}"
  end

  def finding
    Array(check_result&.findings)[finding_index]
  end

  private

  def finding_exists
    errors.add(:finding_index, :invalid) if finding_index.negative? || finding.nil?
  end
end
