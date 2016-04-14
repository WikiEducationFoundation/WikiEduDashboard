class LegacyCourseUserImporter
  def self.add_users(data, role, course, save=true)
    data.map do |p|
      add_user(p, role, course, save)
    end
  end

  def self.add_user(user, role, course, save=true)
    empty_user = User.new(id: user['id'])
    new_user = save ? User.find_or_create_by(id: user['id']) : empty_user
    new_user.username = user['username']
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
end
