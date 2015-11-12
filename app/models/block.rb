# == Schema Information
#
# Table name: blocks
#
#  id                  :integer          not null, primary key
#  kind                :integer
#  content             :text(65535)
#  week_id             :integer
#  gradeable_id        :integer
#  created_at          :datetime
#  updated_at          :datetime
#  title               :string(255)
#  order               :integer
#  due_date            :date
#  training_module_ids :text(65535)
#

#= Block model
class Block < ActiveRecord::Base
  belongs_to :week
  has_one :gradeable, as: :gradeable_item, dependent: :destroy
  serialize :training_module_ids, Array

  KINDS = {
    'in_class'   => 0,
    'assignment' => 1,
    'milestone'  => 2,
    'custom'     => 3,
  }

  def training_modules
    training_module_ids.collect {|id| TrainingModule.find(id) }
  end
end
