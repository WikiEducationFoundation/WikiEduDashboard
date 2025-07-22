# frozen_string_literal: true

# == Schema Information
#
# Table name: weeks
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  course_id  :integer
#  created_at :datetime
#  updated_at :datetime
#  order      :integer          default(1), not null
#

FactoryBot.define do
  factory :week do
  end
end
