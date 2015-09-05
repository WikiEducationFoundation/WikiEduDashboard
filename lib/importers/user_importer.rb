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
    require "#{Rails.root}/lib/wiki"

    id = Wiki.get_user_id(auth.info.name)
    # Replica can also provide us the id via Replica.get_user_id.
    # However, Wiki will always have an up-to-date database, while
    # there may be replication lag for the one Replica uses.
    # If the user account was just created, this means the user_id
    # may not be available on Replica yet.
    user = User.create(
      id: id,
      wiki_id: auth.info.name,
      global_id: auth.uid,
      wiki_token: auth.credentials.token,
      wiki_secret: auth.credentials.secret
    )
    user
  end

  def self.new_from_wiki_id(wiki_id)
    require "#{Rails.root}/lib/wiki"
    id = Wiki.get_user_id(wiki_id)
    return unless id
    user = User.create(
      id: id,
      wiki_id: wiki_id
    )
    user
  end

  def self.add_users(data, role, course, save=true)
    data.map do |p|
      add_user(p, role, course, save)
    end
  end

  def self.add_user(user, role, course, save=true)
    empty_user = User.new(id: user['id'])
    new_user = save ? User.find_or_create_by(id: user['id']) : empty_user
    new_user.wiki_id = user['username']
    if save
      if !role.nil? && !course.nil?
        role_index = %w(student instructor online_volunteer
                        campus_volunteer wiki_ed_staff)
        has_user = course.users.role(role_index[role]).include? new_user
        unless has_user
          role = get_wiki_ed_role(user, role)
          CoursesUsers.new(user: new_user, course: course, role: role).save
        end
      end
      new_user.save
    end
    new_user
  end

  # If a user has (Wiki Ed) in their name, assign them to the staff role
  def self.get_wiki_ed_role(user, role)
    (user['username'].include? '(Wiki Ed)') ? 4 : role
  end

  def self.update_users(users=nil)
    u_users = Utils.chunk_requests(users || User.all) do |block|
      Replica.get_user_info block
    end

    User.transaction do
      u_users.each do |u|
        begin
          User.find(u['id']).update(u.except('id'))
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.warn e
        end
      end
    end
  end
end
