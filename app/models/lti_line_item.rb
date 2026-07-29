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
# `gradable_id` is null in that case. `gradable_type='WikipediaSetup'` is a
# sentinel (also `gradable_id` null) for the per-student "connected a Wikipedia
# account" indicator column — see LtiSetupProgress; it exists on every bound
# course regardless of timeline, and unlike the others is posted for *every*
# discovered student (1.0 once linked, 0.0 while still unlinked).
#
# We never destroy LTIAAS-side line items (it would erase Canvas gradebook
# columns and student grades). When the Dashboard timeline drops a block,
# we set `archived_at` and stop pushing scores to the orphaned line item.
class LtiLineItem < ApplicationRecord
  TRAINING_PROGRESS_TYPE = 'TrainingProgress'
  SETUP_TYPE = 'WikipediaSetup'

  belongs_to :lti_course_binding
  belongs_to :gradable, polymorphic: true, optional: true
  has_many :lti_score_signatures, dependent: :destroy

  # A stored signature means "we already pushed this exact score to this column".
  # `lineitem_id` is mutable — an instructor who deletes an imported Canvas
  # assignment and re-imports it gets a new Canvas line item, and both
  # SyncLtiLineItems#bind_discovered_line_item and
  # ResolveAssignmentLineItem#bind_line_item repoint this row at it rather than
  # creating another. The signatures are keyed on this row's id, so they survived
  # that repoint and described a column that no longer exists: grade sync's
  # `signature_unchanged?` matched, the push was skipped, and the new gradebook
  # column stayed blank with no error and no Sentry event. Because zeros are never
  # seeded either, it wouldn't necessarily self-heal.
  after_update :discard_score_signatures, if: :saved_change_to_lineitem_id?

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  validates :gradable_type, :lineitem_id, presence: true
  validates :score_maximum, numericality: { greater_than: 0 }
  # One line item per (binding, gradable). Enforced in the database by the unique
  # index on (lti_course_binding_id, gradable_key) — `gradable_key` is a stored
  # generated column that folds the sentinels' null gradable_id into a non-null
  # string, because MySQL exempts NULLs from unique indexes. This validation
  # exists on top of it only to turn the race's loser into a handleable error
  # instead of a bare RecordNotUnique.
  validates :gradable_id, uniqueness: { scope: %i[lti_course_binding_id gradable_type] }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current) unless archived?
  end

  private

  def discard_score_signatures
    LtiScoreSignature.where(lti_line_item_id: id).delete_all
  end
end
