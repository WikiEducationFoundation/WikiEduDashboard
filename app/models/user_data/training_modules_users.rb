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
#  flags                :text(65535)
#
require_dependency "#{Rails.root}/lib/training_progress_manager"

class TrainingModulesUsers < ApplicationRecord
  belongs_to :user
  belongs_to :training_module

  serialize :flags, Hash

  def furthest_slide?(slide_slug)
    return true if last_slide_completed.nil?
    training_progress_manager.slide_further_than_previous?(slide_slug, last_slide_completed)
  end

  def mark_completion(value=true, course_id=nil)
    flags[course_id] = { marked_complete: value }
  end

  def eligible_for_completion?(wiki)
    # If module doesn't have a sandbox_location, there's nothing to check.
    return true unless training_module.sandbox_location

    # Via the API, we send the title without the URL encoding of special characters.
    sandbox_content = WikiApi.new(wiki).get_page_content CGI.unescape exercise_sandbox_location
    sandbox_content.present?
  end

  # This is only used on Wiki Education Dashboard
  # so we will assume User: prefix for en.wiki
  def exercise_sandbox_location
    "User:#{user.url_encoded_username}/#{training_module.sandbox_location}"
  end

  private

  def training_progress_manager
    @manager ||= TrainingProgressManager.new(user, training_module,
                                             training_module_user: self)
  end
end
