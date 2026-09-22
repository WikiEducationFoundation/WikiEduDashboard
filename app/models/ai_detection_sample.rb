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
#  provenance    :string(255)
#  notes         :text(65535)
#  factors       :text(65535)
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
  serialize :factors, type: Hash

  # ground_truth: what we know about how the text was produced, independent of
  # any detector. Nil means we know nothing.
  HUMAN = 'human'
  AI = 'ai'
  AI_ASSISTED = 'ai_assisted' # Human writing edited or expanded with AI
  GROUND_TRUTHS = [HUMAN, AI, AI_ASSISTED].freeze

  # provenance: how we know. Free-form so ad-hoc sources can describe
  # themselves; these are the conventions the analysis understands.
  PRE_LLM_TERM = 'pre_llm_term' # Written before ChatGPT existed
  SELF_REPORT = 'self_report' # Student questionnaire answer; recorded, never trusted as truth
  STAFF_CONFIRMED = 'staff_confirmed' # A person looked at the case and concluded
  EXPERIMENT = 'experiment' # Controlled experiment with known conditions
  SYNTHETIC = 'synthetic' # Produced for testing, by us or another AI-writing process

  validates :sample_name, presence: true
  validates :plain_text, presence: true
  validates :ground_truth, inclusion: { in: GROUND_TRUTHS }, allow_nil: true
  validate :factors_are_flat

  before_validation :derive_text_stats

  scope :named, ->(sample_name) { where(sample_name:) }

  def self.sample_names
    distinct.order(:sample_name).pluck(:sample_name)
  end

  def scored_with?(check_type)
    revision_ai_scores.where(check_type:).where.not(avg_ai_likelihood: nil).exists?
  end

  # Units in the same sample that share this unit's value for a factor.
  def linked_by(factor)
    value = factors[factor.to_s]
    return AiDetectionSample.none if value.nil?

    AiDetectionSample.named(sample_name).where.not(id:).select do |unit|
      unit.factors[factor.to_s] == value
    end
  end

  private

  def derive_text_stats
    return if plain_text.blank?

    self.text_sha256 = Digest::SHA256.hexdigest(plain_text)
    self.word_count = plain_text.split.size
  end

  # Factors are simple name → value pairs so they can be flattened into export columns.
  def factors_are_flat
    return if factors.blank?
    return if factors.all? { |key, value| key.is_a?(String) && !value.is_a?(Enumerable) }

    errors.add(:factors, 'must map string names to scalar values')
  end
end
