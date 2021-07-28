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
end
