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
#  duration     :integer          default(1)
#

#= Block model
class Block < ActiveRecord::Base
  belongs_to :week
  has_one :gradeable, as: :gradeable_item
  before_destroy :cleanup

  def pretty_kind
    index = %w(Class Assignment Milestone Custom)
    index[kind]
  end

  def cleanup
    Gradeable.destroy gradeable_id unless gradeable_id.nil?
  end
end
