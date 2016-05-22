require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/wiki_api"

#= Imports and updates users from Wikipedia into the dashboard database
class UserImporter
  def self.from_omniauth(auth)
    user = User.find_by(username: auth.info.name)
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

    id = WikiApi.new.get_user_id(auth.info.name)
    user = User.create(
      id: id,
      username: auth.info.name,
      global_id: auth.uid,
      wiki_token: auth.credentials.token,
      wiki_secret: auth.credentials.secret
    )
    user
  end

  def self.new_from_username(username, wiki: nil)
    # All mediawiki usernames have the first letter capitalized, although
    # the API returns data if you replace it with lower case.
    username[0] = username[0].mb_chars.capitalize.to_s
    user = User.find_by(username: username)
    return user if user

    id = WikiApi.new(wiki).get_user_id(username)
    return unless id

    User.find_or_create_by(username: username)
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

  def self.update_user_from_replica_data(user_data)
    username = user_data['wiki_id']
    user = User.find_by(username: username)
    return if user.blank?
    user.update!(user_data.except('id'))
  end
end
