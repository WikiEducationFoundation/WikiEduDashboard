class LegacyCourseUserImporter
  def self.add_users(data, role, course)
    data.map do |user_data|
      add_user(user_data, role, course)
    end
  end

  def self.add_user(user_data, role, course)
    user = User.find_or_create_by(id: user_data['id'])
    user.username = user_data['username']
    user.save

    return user if role.nil? || course.nil?
    role = get_wiki_ed_role(user_data, role)
    return user if course_has_user_in_role?(course, user, role)
    CoursesUsers.new(user: user, course: course, role: role).save
    user
  end

  # If a user has (Wiki Ed) in their name, assign them to the staff role
  def self.get_wiki_ed_role(user_data, role)
    (user_data['username'].include? '(Wiki Ed)') ? 4 : role
  end

  ROLE_INDEX = %w(student instructor online_volunteer
                  campus_volunteer wiki_ed_staff).freeze

  def self.course_has_user_in_role?(course, user, role)
    course.users.role(ROLE_INDEX[role]).include? user
  end
end
