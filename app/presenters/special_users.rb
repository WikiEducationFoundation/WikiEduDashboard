# frozen_string_literal: true

#= Presenter for Setting / special users
class SpecialUsers
  POSITIONS = %i[
    communications_manager
    classroom_program_manager
    outreach_manager
    technical_help_staff
    survey_alerts_recipient
  ].freeze

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
