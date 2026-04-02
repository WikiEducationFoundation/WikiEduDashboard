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
#
class RevisionAiScore < ApplicationRecord
  belongs_to :wiki
  belongs_to :article
  belongs_to :course
  belongs_to :user

  serialize :details, type: Hash

  include ArticleViewerLinker

  PANGRAM_V2_KEY = 'Pangram 2.0' # This version got deperecated on April, 1st, 2026
  PANGRAM_V3_KEY = 'Pangram 3'
  ORIGINALITY_TURBO_KEY = 'Originality Turbo'
  ORIGINALITY_ACADEMIC_KEY = 'Originality Academic'
  ORIGINALITY_LITE_KEY = 'Originality Lite'
  ORIGINALITY_LITE_BETA_KEY = 'Originality Lite 1.0.2'

  COURSE_UPDATE_ORIGIN = 'course_update'
  AI_TOOL_ORIGIN = 'ai_tool'

  PANGRAM_KEYS = [
    PANGRAM_V3_KEY
  ]

  ORIGINALITY_KEYS = [
    ORIGINALITY_TURBO_KEY,
    ORIGINALITY_ACADEMIC_KEY,
    ORIGINALITY_LITE_KEY,
    ORIGINALITY_LITE_BETA_KEY
  ]

  MODELS_KEY = [
    PANGRAM_V3_KEY,
    ORIGINALITY_TURBO_KEY,
    ORIGINALITY_ACADEMIC_KEY,
    ORIGINALITY_LITE_KEY,
    ORIGINALITY_LITE_BETA_KEY
  ].freeze
end
