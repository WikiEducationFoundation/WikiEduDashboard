# frozen_string_literal: true
require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/wiki_api"

#= Imports and updates users from Wikipedia into the dashboard database
class UserImporter
  def self.from_omniauth(auth)
    user = User.find_by(username: auth.info.name)
    if user.nil?
      user = User.find_by(global_id: auth.uid)
      user&.update_attribute(:username, auth.info.name)
    end

    if user.nil?
      user = new_from_omniauth(auth)
    else
      user.update(global_id: auth.uid,
                  wiki_token: auth.credentials.token,
                  wiki_secret: auth.credentials.secret)
    end
    user
  end

  def self.new_from_omniauth(auth)
    require "#{Rails.root}/lib/wiki_api"

    user = User.create(
      username: auth.info.name,
      global_id: auth.uid,
      wiki_token: auth.credentials.token,
      wiki_secret: auth.credentials.secret
    )
    user
  end

  def self.new_from_username(username)
    # All mediawiki usernames have the first letter capitalized, although
    # the API returns data if you replace it with lower case.
    username = String.new(username)
    # TODO: mb_chars for capitalzing unicode should not be necessary with Ruby 2.4
    username[0] = username[0].mb_chars.capitalize.to_s
    # Remove any leading or trailing whitespace that snuck through.
    username.strip!
    user = User.find_by(username: username)
    return user if user

    # User doesn't exist, so let's create it.
    return unless user_exists_on_meta?(username)
    # Check that user isn't a new username for an existing user.
    global_id = get_global_id(username)
    existing_user = User.find_by(global_id: global_id)
    if user_with_same_global_id_exists?(username)
      existing_user.update_attribute(:username, username)
      return existing_user
    else
      return User.find_or_create_by(username: username)
    end
  end

  def self.update_users(users=nil)
    u_users = Utils.chunk_requests(users || User.all) do |block|
      Replica.new.get_user_info block
    end

    User.transaction do
      u_users.each do |user_data|
        update_user_from_replica_data(user_data)
      end
    end
  end

  def self.user_exists_on_meta?(username)
    # All users are expected to have an account on the central wiki, no matter
    # which is their home wiki.
    WikiApi.new(MetaWiki.new).get_user_id(username).present?
  end

  def self.user_with_same_global_id_exists?(username)
    global_id = get_global_id(username)
    return false unless global_id
    existing_user = User.find_by(global_id: global_id)
    existing_user.present?
  end

  def self.get_global_id(username)
    user_data = Replica.new.get_user_info [User.new(username: username)]
    user_data = user_data[0]
    return unless user_data
    user_data['global_id'].to_i
  end

  def self.update_user_from_replica_data(user_data)
    username = user_data['wiki_id']
    user = User.find_by(username: username)
    return if user.blank?
    user.update!(user_data.except('id'))
  end
end
