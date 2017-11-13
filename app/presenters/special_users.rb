# frozen_string_literal: true

#= Presenter for Setting / special users
class SpecialUsers
  def self.special_users
    Setting.find_or_create_by(key: 'special_users').value
  end

  def self.communications_manager
    User.find_by(username: special_users[:communications_manager])
  end

  def self.classroom_program_manager
    User.find_by(username: special_users[:classroom_program_manager])
  end

  def self.outreach_manager
    User.find_by(username: special_users[:outreach_manager])
  end

  def self.technical_help_staff
    User.find_by(username: special_users[:technical_help_staff])
  end

  def self.survey_alerts_recipient
    User.find_by(username: special_users[:survey_alerts_recipient])
  end
end
