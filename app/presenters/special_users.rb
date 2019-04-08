# frozen_string_literal: true

#= Presenter for Setting / special users
class SpecialUsers
  # #########
  # Getters #
  # #########
  def self.special_users
    Setting.find_or_create_by(key: 'special_users').value
  end

  # Checks if the user is a Special User of the given position
  def self.is?(user, position)
    if position == 'wikipedia_experts'
      wikipedia_experts.include? user
    else
      SpecialUsers.special_users[position.to_sym] == user.username
    end
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

  def self.wikipedia_experts
    User.where(username: special_users[:wikipedia_experts])
  end

  def self.technical_help_staff
    User.find_by(username: special_users[:technical_help_staff])
  end

  def self.survey_alerts_recipient
    User.find_by(username: special_users[:survey_alerts_recipient])
  end

  def self.backup_account_creator
    User.find_by(username: special_users[:backup_account_creator])
  end

  # #########
  # Setters #
  # #########
  def self.set_user(role, username)
    if role == 'wikipedia_experts'
      experts = special_users[:wikipedia_experts] || []
      Setting.set_hash('special_users', role.to_sym, experts + [username])
    else
      Setting.set_hash('special_users', role.to_sym, username)
    end
  end

  def self.remove_user(role, username: nil)
    users = Setting.find_or_create_by(key: 'special_users')

    if role == 'wikipedia_experts'
      experts = special_users[:wikipedia_experts] || []
      Setting.set_hash('special_users', role.to_sym, experts - [username])
    else
      users.value.delete(role.to_sym)
    end

    users.save
  end
end
