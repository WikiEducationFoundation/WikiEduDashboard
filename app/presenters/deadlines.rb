# frozen_string_literal: true

class Deadlines
  # This is the method used for loading the notice for
  # the course creator and cloning UI. We load the setting
  # from the DB here to make sure it's up to date across
  # all application servers after a settings change.
  def self.course_creation_notice
    reload_setting_record
    return unless deadline
    Time.zone.today < deadline ? before_deadline_message : after_deadline_message
  end

  # Used to render the values in the /settings UI.
  def self.student_program
    setting_record.value['student_program']
  end

  def self.update_student_program(recruiting_term:, deadline:,
                                  before_deadline_message:, after_deadline_message:)
    record = Setting.find_or_create_by(key: 'deadlines')
    record.value['student_program'] = {
      recruiting_term:,
      deadline:,
      before_deadline_message:,
      after_deadline_message:
    }
    record.save
    @setting_record = record
  end

  ##################
  # Helper methods #
  ##################
  def self.reload_setting_record
    @setting_record = Setting.find_or_create_by(key: 'deadlines')
  end

  def self.setting_record
    @setting_record ||= Setting.find_or_create_by(key: 'deadlines')
  end

  # These are injected into React via a `data` attribute.
  # We replace any single-quotes with apostrophes so it doesn't
  # break the syntax when used as raw inner HTML.
  def self.after_deadline_message
    student_program[:after_deadline_message]&.tr("'", '’')
  end

  def self.before_deadline_message
    student_program[:before_deadline_message]&.tr("'", '’')
  end

  def self.deadline
    student_program&.dig(:deadline)&.to_date
  end

  def self.recruiting_term
    student_program&.dig(:recruiting_term)
  end
end
