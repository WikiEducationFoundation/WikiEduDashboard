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
#  is_deletable        :boolean          default(TRUE)
#  is_editable         :boolean          default(TRUE)
#

require_dependency "#{Rails.root}/lib/block_date_manager"

#= Block model
class Block < ApplicationRecord
  belongs_to :week
  has_one :course, through: :week
  serialize :training_module_ids, Array
  before_update :editable?, if: :content_fields_changed?
  before_destroy :deletable?
  default_scope { includes(:week, :course) }

  KINDS = {
    'in_class'   => 0,
    'assignment' => 1,
    'milestone'  => 2,
    'custom'     => 3,
    'handouts'   => 4
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

  def editable?
    throw :abort unless is_editable
  end

  def content_fields_changed?
    content_changed? || title_changed? || training_module_ids_changed?
  end

  def deletable?
    throw :abort unless is_deletable
  end
end
