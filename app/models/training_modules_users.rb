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
require_dependency "#{Rails.root}/lib/training_progress_manager"

class TrainingModulesUsers < ApplicationRecord
  belongs_to :user

  def training_module
    @training_module ||= TrainingModule.find(training_module_id)
  end

  def furthest_slide?(slide_slug)
    return true if last_slide_completed.nil?
    training_progress_manager.slide_further_than_previous?(slide_slug, last_slide_completed)
  end

  private

  def training_progress_manager
    @manager ||= TrainingProgressManager.new(user, training_module,
                                             training_module_user: self)
  end
end
