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
#  created_at           :datetime
#  updated_at           :datetime
#

class TrainingModulesUsers < ApplicationRecord
  belongs_to :user

  def training_module
    TrainingModule.find(training_module_id)
  end
end
