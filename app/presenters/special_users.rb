# frozen_string_literal: true

#= Presenter for Setting / special users
class SpecialUsers
<<<<<<< HEAD
  POSITIONS = %i[
    communications_manager
    classroom_program_manager
    outreach_manager
    technical_help_staff
    survey_alerts_recipient
  ].freeze
=======
  def self.special_users
    Setting.find_or_create_by(key: 'special_users').value
  end

  def self.set(role, username)
    Setting.set_hash('special_users', role, username)
  end

  def self.communications_manager
    User.find_by(username: special_users[:communications_manager])
  end
>>>>>>> ffa28b0d909147f7dfc8ee83462c02b244e4ee2a

  class << self
    def special_users
      Setting.find_or_create_by(key: 'special_users').value
    end

    # Dynamically define class methods
    POSITIONS.each do |position|
      define_method position do
        User.find_by(username: special_users[position])
      end
    end
  end

  def self.all_grouped
    special_users = {}
    POSITIONS.each do |position|
      special_users[position] = send(position)
    end
    special_users
  end
end
