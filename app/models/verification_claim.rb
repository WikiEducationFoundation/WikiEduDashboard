# frozen_string_literal: true

# == Schema Information
#
# Table name: verification_claims
#
#  id               :bigint           not null, primary key
#  sentence         :text(65535)      not null
#  context          :text(65535)
#  cite_text        :text(65535)
#  source_url       :text(65535)
#  archive_url      :text(65535)
#  offline_source   :boolean
#  ref_id           :string(255)
#  article_id       :integer
#  article_title    :string(255)
#  wiki_id          :integer          not null
#  mw_rev_id        :integer
#  source_course_id :integer
#  courses_users_id :integer
#  subject          :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

# A cited factual claim harvested from an article a past-term course worked
# on, stored as candidate material for the claim-verification exercise. Each
# record is one (claim sentence, cited source) pair. Every cited claim is
# kept; `offline_source` flags those whose citation exposes no openable URL,
# and `courses_user` records the enrolling student when the claim was
# harvested from that student's own added content. No serving/eligibility
# filtering is applied here — that is left to a later serving layer.
class VerificationClaim < ApplicationRecord
  belongs_to :wiki
  belongs_to :article, optional: true
  belongs_to :source_course, class_name: 'Course', optional: true
  belongs_to :courses_user, class_name: 'CoursesUsers',
             foreign_key: 'courses_users_id', optional: true

  validates :sentence, presence: true

  scope :for_subject, ->(subject) { where(subject:) }
  scope :student_added, -> { where.not(courses_users_id: nil) }
end
