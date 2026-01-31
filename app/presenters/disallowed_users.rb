# frozen_string_literal: true

#= Presenter for Setting / disallowed users (bot accounts)
class DisallowedUsers
  SETTING_KEY = 'disallowed_users'

  # #########
  # Getters #
  # #########
  def self.disallowed_usernames
    Setting.find_or_create_by(key: SETTING_KEY).value[:usernames] || []
  end

  def self.disallowed?(username)
    disallowed_usernames.include?(username)
  end

  # #########
  # Setters #
  # #########
  def self.add_user(username)
    usernames = disallowed_usernames
    return false if usernames.include?(username)
    Setting.set_hash(SETTING_KEY, :usernames, usernames + [username])
    true
  end

  def self.remove_user(username)
    usernames = disallowed_usernames
    return false unless usernames.include?(username)
    Setting.set_hash(SETTING_KEY, :usernames, usernames - [username])
    true
  end
end
