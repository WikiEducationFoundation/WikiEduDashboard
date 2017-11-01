# frozen_string_literal: true

# == Schema Information
#
# Table name: training_modules_users
#
#  id                   :integer          not null, primary key
#  user_id              :integer
#  training_module_id   :integer
#  last_slide_completed :string(255)
#  completed_at         :datetime
#

FactoryBot.define do
  factory :training_modules_users do
  end
end
