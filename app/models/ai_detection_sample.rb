# frozen_string_literal: true
# == Schema Information
#
# Table name: ai_detection_samples
#
#  id            :bigint           not null, primary key
#  sample_name   :string(255)      not null
#  wiki_id       :integer
#  rev_id        :integer
#  from_rev_id   :integer
#  diff_mode     :boolean          default(TRUE), not null
#  url           :string(255)
#  article_id    :integer
#  course_id     :integer
#  campaign_slug :string(255)
#  namespace     :integer
#  ground_truth  :string(255)
#  plain_text    :text(16777215)
#  text_sha256   :string(64)
#  word_count    :integer
#  metadata      :text(65535)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

# One text unit of a named detector-comparison sample. See
# BuildAiDetectionSample for how units are assembled and ScoreAiDetectionSample
# for how they are sent to detectors.
class AiDetectionSample < ApplicationRecord
  belongs_to :wiki, optional: true
  belongs_to :article, optional: true
  belongs_to :course, optional: true
  has_many :revision_ai_scores, foreign_key: :sample_id, inverse_of: :sample,
                                dependent: :nullify

  serialize :metadata, type: Hash

  # What we know about how the text was produced, independent of any detector.
  HUMAN_PRE_LLM = 'human_pre_llm' # Written before ChatGPT existed
  SELF_REPORTED_AI = 'self_reported_ai' # Student follow-up acknowledged AI use
  SELF_REPORTED_NO_AI = 'self_reported_no_ai' # Student follow-up disputed the alert
  EXPERIMENT_AI = 'experiment_ai' # Known AI output from a controlled experiment
  UNKNOWN = 'unknown'
  GROUND_TRUTHS = [HUMAN_PRE_LLM, SELF_REPORTED_AI, SELF_REPORTED_NO_AI,
                   EXPERIMENT_AI, UNKNOWN].freeze

  validates :sample_name, presence: true
  validates :plain_text, presence: true
  validates :ground_truth, inclusion: { in: GROUND_TRUTHS }, allow_nil: true

  before_validation :derive_text_stats

  scope :named, ->(sample_name) { where(sample_name:) }

  def self.sample_names
    distinct.order(:sample_name).pluck(:sample_name)
  end

  def scored_with?(check_type)
    revision_ai_scores.where(check_type:).where.not(avg_ai_likelihood: nil).exists?
  end

  private

  def derive_text_stats
    return if plain_text.blank?

    self.text_sha256 = Digest::SHA256.hexdigest(plain_text)
    self.word_count = plain_text.split.size
  end
end
