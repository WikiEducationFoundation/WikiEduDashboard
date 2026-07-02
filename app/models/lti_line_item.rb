# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_line_items
#
#  id                       :integer          not null, primary key
#  lti_course_binding_id    :integer          not null
#  gradable_type            :string(255)      not null
#  gradable_id              :integer
#  lineitem_id              :string(512)      not null
#  label                    :string(255)
#  score_maximum            :decimal(10, 4)   default(1.0), not null
#  archived_at              :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  canvas_assignment_id     :string(255)      - Canvas-side assignment id, used
#                                               to route assignment_view launches
#                                               back to this line item; nil until
#                                               first captured/backfilled
#

# Maps a Dashboard gradable unit to an LTIAAS-managed LMS gradebook line
# item.
#
# `gradable_type='Block'` is the per-block mapping used when a binding's
# granularity is 'per_block'. `gradable_type='TrainingProgress'` is a
# sentinel used in 'lumped' mode for the rolled-up trainings column;
# `gradable_id` is null in that case.
#
# We never destroy LTIAAS-side line items (it would erase Canvas gradebook
# columns and student grades). When the Dashboard timeline drops a block,
# we set `archived_at` and stop pushing scores to the orphaned line item.
class LtiLineItem < ApplicationRecord
  TRAINING_PROGRESS_TYPE = 'TrainingProgress'

  belongs_to :lti_course_binding
  belongs_to :gradable, polymorphic: true, optional: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  validates :gradable_type, :lineitem_id, presence: true
  validates :score_maximum, numericality: { greater_than: 0 }
  validates :gradable_id,
            uniqueness: { scope: %i[lti_course_binding_id gradable_type] },
            allow_nil: true

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current) unless archived?
  end
end
