# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/wiki_api"

#= Imports and updates users from Wikipedia into the dashboard database
class UserImporter
  def self.from_omniauth(auth)
    user = User.find_by(username: auth.info.name)
    user ||= User.find_by(global_id: auth.uid)

    return new_from_omniauth(auth) if user.nil?
    update_user_from_auth(user, auth)
    user
  end

  def self.new_from_omniauth(auth)
    user = User.create(
      username: auth.info.name,
      global_id: auth.uid,
      wiki_token: auth.credentials.token,
      wiki_secret: auth.credentials.secret
    )
    user
  end

  LTR_MARK = 8206.chr # left-to-right mark, Ruby character 8206
  RTL_MARK = 8207.chr # right-to-left mark, Ruby character 8207
  CHARACTERS_TO_TRIM = [LTR_MARK, RTL_MARK].freeze

  def self.new_from_username(username, home_wiki=nil)
    username = sanitize_username(username)
    user = User.find_by(username:)
    return user if user

    # All users are expected to have an account on the central wiki, no matter
    # which is their home wiki.
    return unless user_account_exists?(username, home_wiki)

    # We may already have a user record, but the user has been renamed.
    # We check for a user with the same global_id, and update the username if
    # we find one.
    update_username_for_global_id(username)

    # At this point, if we still can't find a record with this username,
    # we finally create and return it.
    return User.find_or_create_by(username:)
  end

  # There are some users who have a local wiki account, but do not have one
  # on MetaWiki, so this can be used to check for registration date on MetaWiki by default,
  # but also for other wikis if needed.
  def self.update_users(users=nil, wiki=nil)
    wiki ||= MetaWiki.new
    users ||= User.where(registered_at: nil)
    users.each do |user|
      update_user_from_wiki(user, wiki)
    end
  end

  ##################
  # Helper methods #
  ##################

  def self.update_user_from_auth(user, auth)
    user.update(global_id: auth.uid,
                username: auth.info.name,
                wiki_token: auth.credentials.token,
                wiki_secret: auth.credentials.secret)
  end

  def self.sanitize_username(username)
    username = String.new(username)
    # mediawiki mostly treats spaces and underscores as equivalent, but spaces
    # are the canonical form. Replica will not return revisions for the underscore
    # versions.
    username.tr!('_', ' ')
    # Remove any leading or trailing whitespace that snuck through.
    username.gsub!(/^[[:space:]]+/, '')
    username.gsub!(/[[:space:]]+$/, '')

    # Remove common invisible characters from beginning or end of username
    username[0] = '' while CHARACTERS_TO_TRIM.include? username[0]
    username[-1] = '' while CHARACTERS_TO_TRIM.include? username[-1]
    # Remove "User:" prefix if present.
    username.gsub!(/^User:/, '')
    # All mediawiki usernames have the first letter capitalized, although
    # the API returns data if you replace it with lower case.
    username[0] = username[0].capitalize.to_s unless username.empty?
    return username
  end

  def self.user_account_exists?(username, home_wiki)
    # First check Meta, then fall back to specified home wiki.
    return true if WikiApi.new(MetaWiki.new).get_user_id(username).present?
    # If home_wiki is nil, WikiApi falls back to the default wiki (en.wikipedia)
    WikiApi.new(home_wiki).get_user_id(username).present?
  end

  def self.update_username_for_global_id(username)
    existing_user = user_with_same_global_id(username)
    existing_user&.update_attribute(:username, username)
  end

  def self.user_with_same_global_id(username)
    global_id = get_global_id(username)
    return unless global_id
    User.find_by(global_id:)
  end

  def self.get_global_id(username)
    user_data = WikiApi.new(MetaWiki.new).get_user_info(username)
    user_data&.dig('centralids', 'CentralAuth')
  end

  def self.update_user_from_wiki(user, wiki)
    user_data = WikiApi.new(wiki).get_user_info(user.username)
    return if user_data['missing']
    user.update!(username: user_data['name'],
                 registered_at: user_data['registration'],
                 global_id: user_data&.dig('centralids', 'CentralAuth'))
  rescue ActiveRecord::RecordNotUnique => e
    handle_duplicate_user(user, user_data)
    Sentry.capture_exception e, extra: { username: user.username, user_id: user.id }
  end

  def self.handle_duplicate_user(user, user_data)
    existing_user = User.find_by(username: user_data['name'])
    user.revisions.update_all(user_id: existing_user.id)
    user.courses_users.each do |cu|
      next if CoursesUsers.exists?(course_id: cu.course_id, user_id: existing_user.id)
      cu.update(user_id: existing_user.id)
    end
    # This destroys remaining duplicate CoursesUsers records as well.
    # Reload prevents destruction of any updated CoursesUsers.
    user.reload.destroy
  end
end
