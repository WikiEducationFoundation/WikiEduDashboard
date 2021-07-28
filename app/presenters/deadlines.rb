# frozen_string_literal: true

class Deadlines
  def self.setting_record
    @setting_record ||= Setting.find_or_create_by(key: 'deadlines')
  end

  def self.update_student_program(recruiting_term:, deadline:,
                                  before_deadline_message:, after_deadline_message:)
    record = Setting.find_or_create_by(key: 'deadlines')
    record.value['student_program'] = {
      recruiting_term: recruiting_term,
      deadline: deadline,
      before_deadline_message: before_deadline_message,
      after_deadline_message: after_deadline_message
    }
    record.save
    @setting_record = record
  end

  def self.student_program
    setting_record.value['student_program']
  end

  # We use `raw` to put these into a JavaScript object in _head.html.haml
  # We replace any single-quotes with apostrophes so it doesn't break the syntax.
  def self.after_deadline_message
    student_program[:after_deadline_message]&.tr("'", '’')
  end

  def self.before_deadline_message
    student_program[:before_deadline_message]&.tr("'", '’')
  end

  def self.deadline
    student_program&.dig(:deadline)&.to_date
  end

  def self.course_creation_notice
    return unless deadline
    Time.zone.today < deadline ? before_deadline_message : after_deadline_message
  end
end
