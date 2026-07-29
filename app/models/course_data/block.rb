# frozen_string_literal: true
# == Schema Information
#
# Table name: blocks
#
#  id                  :integer          not null, primary key
#  kind                :integer
#  content             :text(65535)
#  week_id             :integer
#  created_at          :datetime
#  updated_at          :datetime
#  title               :string(255)
#  order               :integer
#  due_date            :date
#  training_module_ids :text(65535)
#  points              :integer
#

require_dependency "#{Rails.root}/lib/block_date_manager"

#= Block model
class Block < ApplicationRecord
  belongs_to :week
  has_one :course, through: :week
  serialize :training_module_ids, type: Array
  default_scope { includes(:week, :course) }

  # If this block belongs to a course bound to Canvas via LTIAAS, fire a
  # debounced line-item sync so the Dashboard's own mapping keeps up with the
  # timeline: a block that gains or loses an exercise becomes newly importable or
  # gets its column archived, and a retitled block updates its local label. This
  # pushes nothing to Canvas — the instructor named the assignment at import time
  # and Canvas owns it from there. The 2-minute delay collapses bulk edits
  # (e.g. wizard re-runs, manual rearrangements) under sidekiq-unique-jobs'
  # :until_executed lock.
  after_commit :enqueue_lti_line_item_sync, on: %i[create update destroy]

  KINDS = {
    'in_class'   => 0,
    'assignment' => 1,
    'milestone'  => 2,
    'custom'     => 3,
    'handouts'   => 4,
    'resources'  => 5
  }.freeze

  DEFAULT_POINTS = 10

  def training_modules
    TrainingModule.where(id: training_module_ids)
  end

  def date_manager
    @date_manager ||= BlockDateManager.new(self)
  end

  def calculated_date
    date_manager.date
  end

  def calculated_due_date
    date_manager.due_date
  end

  private

  def enqueue_lti_line_item_sync
    return unless Features.canvas_integration?

    binding = LtiCourseBinding.find_by(course_id: course&.id)
    return unless binding

    LtiLineItemSyncWorker.perform_in(2.minutes, binding.id)
  end
end
