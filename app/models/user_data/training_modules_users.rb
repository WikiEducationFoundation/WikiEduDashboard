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

  serialize :flags, type: Hash

  def furthest_slide?(slide_slug)
    return true if last_slide_completed.nil?
    training_progress_manager.slide_further_than_previous?(slide_slug, last_slide_completed)
  end

  # Keeps any other per-course flags, such as the exercise article title.
  def mark_completion(value = true, course_id = nil)
    flags[course_id] = (flags[course_id] || {}).merge(marked_complete: value)
  end

  # For article_title_input exercises, the title is only stored once the
  # student's edit to it has been verified, which also completes the exercise.
  def store_exercise_article_title(title, course_id)
    flags[course_id] = (flags[course_id] || {}).merge(marked_complete: true,
                                                      exercise_article_title: title)
  end

  def exercise_article_title(course_id)
    flags.dig(course_id, :exercise_article_title)
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
