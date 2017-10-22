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

class TrainingModulesUsers < ActiveRecord::Base
  belongs_to :user

  def training_module
    TrainingModule.find(training_module_id)
  end
end
