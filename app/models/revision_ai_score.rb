# frozen_string_literal: true
# == Schema Information
#
# Table name: revision_ai_scores
#
#  id                :bigint           not null, primary key
#  revision_id       :integer
#  wiki_id           :integer
#  course_id         :integer
#  user_id           :integer
#  article_id        :integer
#  revision_datetime :datetime
#  avg_ai_likelihood :float(24)
#  max_ai_likelihood :float(24)
#  details           :text(65535)
#  check_type        :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  url               :string(255)
#  check_origin      :string(255)
#  origin_user_id    :integer
#  sample_id         :integer
#
class RevisionAiScore < ApplicationRecord
  belongs_to :wiki
  belongs_to :article
  belongs_to :course
  belongs_to :user
  # Set when the row was scored as part of a detector comparison sample.
  belongs_to :sample, class_name: 'AiDetectionSample', optional: true,
                      inverse_of: :revision_ai_scores

  serialize :details, type: Hash

  include ArticleViewerLinker

  # check_type values. Each detector that can still be called is registered in
  # AiDetector (lib/ai/ai_detector.rb) under its key; retired keys stay here so
  # old rows remain identifiable.
  PANGRAM_V2_KEY = 'Pangram 2.0' # Deprecated on 1 April 2026
  PANGRAM_V3_KEY = 'Pangram 3' # Synchronous API, shut down on 30 September 2026
  # Production alerting. Whatever version Pangram serves as pangram-4: 4.0 until
  # 2026-10-19, 4.1 since; details['version'] tells them apart.
  PANGRAM_V4_KEY = 'Pangram 4'
  PANGRAM_V4_0_KEY = 'Pangram 4.0' # Detector comparison rows scored before 2026-10-19
  PANGRAM_V4_1_KEY = 'Pangram 4.1' # Refuses any other version
  # Originality.ai's classic models and AI Allowance mode, retired in favour of 5.0.
  ORIGINALITY_TURBO_KEY = 'Originality Turbo'
  ORIGINALITY_ACADEMIC_KEY = 'Originality Academic'
  ORIGINALITY_LITE_KEY = 'Originality Lite 1.0.0'
  ORIGINALITY_LITE_102_KEY = 'Originality Lite 1.0.2'
  ORIGINALITY_AI_ALLOWANCE_15_KEY = 'Originality AI Allowance 15'
  ORIGINALITY_AI_ALLOWANCE_40_KEY = 'Originality AI Allowance 40'
  ORIGINALITY_5_KEY = 'Originality 5.0'
  ORIGINALITY_5_MAX_KEY = 'Originality 5.0 Max'

  # check_origin values
  COURSE_UPDATE_ORIGIN = 'course_update' # Production checks that can generate alerts
  AI_TOOL_ORIGIN = 'ai_tool' # Admin AI tools page
  DETECTOR_COMPARISON_ORIGIN = 'detector_comparison' # Scored as part of an AiDetectionSample
  ARTICLE_AUDIT_ORIGIN = 'article_audit' # Scored as a check in an ArticleAudit
end
