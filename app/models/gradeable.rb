# frozen_string_literal: true

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
class Gradeable < ApplicationRecord
  belongs_to :gradeable_item, polymorphic: true
  before_validation :normalize_points

  def normalize_points
    self.points = points.to_i
  end
end
