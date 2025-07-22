# frozen_string_literal: true

class EnrollmentReminderEmailWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  retry: 0 # Move job to the 'dead' queue if it fails

  def self.schedule_reminder(user)
    # We only use this for users who didn't indicate they are instructors,
    # as it is intended to prompt students to use the enrollment link
    # in case something in the enrollment flow went wrong.
    return unless user.permissions == User::Permissions::NONE
    # Also make sure we don't spam people who revisit the onboarding flow.
    return if user.created_at < 1.day.ago

    perform_at(5.minutes.from_now, user.id)
  end

  def perform(user_id)
    user = User.find user_id
    return if user.courses.any?

    EnrollmentReminderMailer.send_reminder(user)
  end
end
