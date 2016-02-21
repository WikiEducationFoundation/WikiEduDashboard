require "#{Rails.root}/lib/replica"

#= Imports and updates users from Wikipedia into the dashboard database
class UserImporter
  def self.from_omniauth(auth)
    user = User.find_by(wiki_id: auth.info.name)
    if user.nil?
      user = new_from_omniauth(auth)
    else
      user.update(
        global_id: auth.uid,
        wiki_token: auth.credentials.token,
        wiki_secret: auth.credentials.secret
      )
    end
    user
  end

  def self.new_from_omniauth(auth)
    require "#{Rails.root}/lib/wiki_api"

    user = User.create(
      wiki_id: auth.info.name,
      global_id: auth.uid,
      wiki_token: auth.credentials.token,
      wiki_secret: auth.credentials.secret
    )
    user
  end

  def self.new_from_wiki_id(wiki_id)
    return unless user_exists?(wiki_id)

    User.find_or_create_by(wiki_id: wiki_id)
  end

  def self.user_exists?(wiki_id)
    require "#{Rails.root}/lib/wiki_api"

    # TODO: Which wiki?  Should use CentralAuth, either way
    true unless WikiApi.new(Wiki.default_wiki).get_user_id(wiki_id).nil?
  end

  def self.add_users(data, role, course, save=true)
    data.map do |p|
      add_user(p, role, course, save)
    end
  end

  def self.add_user(params, role, course, save=true)
    if save
      user = User.find_or_create_by(wiki_id: params['username'])
    else
      user = User.new(wiki_id: params['username'])
    end

    if save
      unless role.nil? || course.nil?
        role_index = %w(student instructor online_volunteer
                        campus_volunteer wiki_ed_staff)
        has_user = course.users.role(role_index[role]).include? user
        unless has_user
          role = get_wiki_ed_role(user, role)
          CoursesUsers.new(user: user, course: course, role: role).save
        end
      end
      user.save
    end
    user
  end

  # If a user has (Wiki Ed) in their name, assign them to the staff role
  # FIXME: Don't do that.  Manage staff user IDs in the database or something.
  def self.get_wiki_ed_role(user, role)
    (user.wiki_id.include? '(Wiki Ed)') ? 4 : role
  end

  def self.update_users(users=nil)
    # FIXME: We're blindly guessing which wiki to query for each user.
    users ||= User.all
    u_users = []
    users.group_by(&:home_wiki).each do |wiki, local_users|
      u_users |= Utils.chunk_requests(local_users) do |block|
        Replica.new(wiki).get_user_info block
      end
    end

    User.transaction do
      u_users.each do |u|
        begin
          User.find_by!(wiki_id: u['wiki_id']).update(u.except('id'))
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.warn e
        end
      end
    end
  end
end
