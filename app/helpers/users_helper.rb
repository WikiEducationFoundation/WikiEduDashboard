# frozen_string_literal: true

#= Helpers for users
module UsersHelper
  def contribution_link(courses_user, text=nil, css_class=nil)
    options = { target: '_blank', class: css_class }
    link_to((text || courses_user.user.username), courses_user.contribution_url, options)
  end

  COURSE_ROLE_MESSAGE_STRINGS = {
    CoursesUsers::Roles::STUDENT_ROLE => 'student',
    CoursesUsers::Roles::INSTRUCTOR_ROLE => 'instructor',
    CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE => 'campus_volunteer',
    CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE => 'online_volunteer',
    CoursesUsers::Roles::WIKI_ED_STAFF_ROLE => 'wiki_ed_staff'
  }.freeze
  def course_role_name(courses_users_role)
    t("users.role.#{COURSE_ROLE_MESSAGE_STRINGS[courses_users_role]}")
  end
end
