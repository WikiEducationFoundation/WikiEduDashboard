# frozen_string_literal: true
# == Schema Information
#
# Table name: confidential_course_details
#
#  id          :bigint           not null, primary key
#  course_id   :integer          not null
#  sequence    :integer          not null
#  real_title  :string(255)
#  real_school :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# The real title and institution of a course in privacy mode. The course's own
# `title` and `school` columns hold obfuscated stand-ins built from `sequence`,
# so everything derived from them — the slug, the on-wiki course page, every
# JSON and CSV serialization — is anonymous without any per-site masking.
#
# Nothing here may be serialized into a course payload. The only surfaces that
# read it are admin-only.
class ConfidentialCourseDetail < ApplicationRecord
  belongs_to :course

  validates :course_id, presence: true, uniqueness: true
  validates :sequence, presence: true, uniqueness: true

  # The next unused sequence. Racy on its own; the unique index on `sequence`
  # and on `courses.slug` are what actually enforce uniqueness, and
  # ObfuscateCourseIdentity retries when it loses the race.
  def self.next_sequence
    (maximum(:sequence) || 0) + 1
  end
end
