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

FactoryBot.define do
  factory :gradeable do
    title 'MyString'
    points 1
  end
end
