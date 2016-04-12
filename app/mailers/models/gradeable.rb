# == Schema Information
#
# Table name: gradeables
#
#  id                  :integer          not null, primary key
#  title               :string(255)
#  points              :integer
#  gradeable_item_id   :integer
#  created_at          :datetime
#  updated_at          :datetime
#  gradeable_item_type :string(255)
#

#= Gradeable model
class Gradeable < ActiveRecord::Base
  belongs_to :gradeable_item, polymorphic: true
end
