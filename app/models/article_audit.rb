# frozen_string_literal: true
# == Schema Information
#
# Table name: article_audits
#
#  id            :bigint           not null, primary key
#  wiki_id       :integer          not null
#  mw_rev_id     :integer          not null
#  mw_page_id    :integer
#  namespace     :integer
#  article_title :string(255)
#  url           :string(1000)
#  article_id    :integer
#  requester_id  :integer
#  course_id     :integer
#  user_id       :integer
#  status        :string(255)      default("queued"), not null
#  error         :text(65535)
#  usage         :text(65535)
#  started_at    :datetime
#  completed_at  :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

# A requested review of one revision of a wiki page. The audit itself is
# just the target and the run state; each check's output is stored as an
# ArticleAuditCheckResult. See RunArticleAudit for how checks are run.
class ArticleAudit < ApplicationRecord
  belongs_to :wiki
  belongs_to :requester, class_name: 'User', optional: true
  belongs_to :article, optional: true
  belongs_to :course, optional: true
  belongs_to :user, optional: true
  has_many :check_results, class_name: 'ArticleAuditCheckResult', dependent: :destroy

  serialize :usage, coder: JSON

  QUEUED = 'queued'
  RUNNING = 'running'
  COMPLETE = 'complete' # every check succeeded
  PARTIAL = 'partial'   # some checks failed
  FAILED = 'failed'     # the audit could not run, or every check failed
  STATUSES = [QUEUED, RUNNING, COMPLETE, PARTIAL, FAILED].freeze
  FINISHED_STATUSES = [COMPLETE, PARTIAL, FAILED].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :mw_rev_id, presence: true

  def finished?
    FINISHED_STATUSES.include?(status)
  end

  def revision_url
    "#{wiki.base_url}/w/index.php?oldid=#{mw_rev_id}"
  end

  # The most recent result for each check. Earlier runs of the same check are
  # kept for comparison but don't appear in the report.
  def latest_check_results
    check_results.order(:id).group_by(&:check_key).transform_values(&:last).values
  end

  # Sets the finished status from the latest result of each check, along with
  # the usage totals. Called when a run finishes and after a check is re-run.
  def finalize!
    latest = latest_check_results
    status = if latest.none?(&:failed?) then COMPLETE
             elsif latest.any?(&:succeeded?) then PARTIAL
             else FAILED
             end
    update!(status:, completed_at: Time.zone.now, usage: total_usage)
  end

  # Sums token usage across every check result, keyed by engine, so cost can
  # be compared between engines.
  def total_usage
    check_results.each_with_object({}) do |result, totals|
      next if result.usage.blank?
      engine_totals = totals[result.engine] ||= Hash.new(0)
      result.usage.each do |key, value|
        engine_totals[key] += value if value.is_a?(Numeric)
      end
    end
  end
end
