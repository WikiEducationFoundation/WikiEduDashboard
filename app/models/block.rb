# == Schema Information
#
# Table name: blocks
#
#  id           :integer          not null, primary key
#  kind         :integer
#  content      :string(5000)
#  week_id      :integer
#  gradeable_id :integer
#  created_at   :datetime
#  updated_at   :datetime
#  title        :string(255)
#  order        :integer
#  due_date     :datetime
#

#= Block model
class Block < ActiveRecord::Base
  belongs_to :week
  has_one :gradeable, as: :gradeable_item, dependent: :destroy

  KINDS = {
    'in_class'   => 0,
    'assignment' => 1,
    'milestone'  => 2,
    'custom'     => 3,
    'training'   => 4
  }

  def training_module
    TrainingModule.find(training_module_id)
  end
end
