# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_course_bindings
#
#  id                         :integer          not null, primary key
#  course_id                  :integer
#  lms_id                     :string(255)      not null
#  lms_family                 :string(255)
#  lms_context_id             :string(255)      not null
#  lms_resource_link_id       :string(255)      not null
#  ltiaas_service_credentials :text(65535)
#  nrps_url                   :string(255)
#  ags_lineitems_url          :string(255)
#  gradebook_granularity      :string(255)      default("lumped"), not null
#  last_roster_sync_at        :datetime
#  last_grade_sync_at         :datetime
#  last_grade_sync_error      :text(65535)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#

# Persists the 1:1 binding between an LMS course/placement and a Dashboard
# Course. Created during an instructor's first launch from Canvas; the
# `course_id` may be nil briefly between binding creation and the
# instructor's setup-flow choice (link existing / create new).
#
# `gradebook_granularity` controls how AGS line items map to the Dashboard
# timeline:
#   - 'lumped'    => one line item rolling up training-module completion
#                    plus one line item per exercise block
#   - 'per_block' => one line item per graded block
class LtiCourseBinding < ApplicationRecord
  GRADEBOOK_GRANULARITIES = %w[lumped per_block].freeze

  belongs_to :course, optional: true
  has_many :lti_contexts, dependent: :destroy
  has_many :lti_line_items, dependent: :destroy

  validates :lms_id, :lms_context_id, :lms_resource_link_id, presence: true
  validates :gradebook_granularity, inclusion: { in: GRADEBOOK_GRANULARITIES }

  def self.lookup(lms_id:, lms_context_id:, lms_resource_link_id:)
    find_by(lms_id:, lms_context_id:, lms_resource_link_id:)
  end

  def lumped?
    gradebook_granularity == 'lumped'
  end

  def per_block?
    gradebook_granularity == 'per_block'
  end
end
