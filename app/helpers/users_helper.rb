# frozen_string_literal: true
#= Helpers for users
module UsersHelper
  def contribution_link(courses_user, text=nil, css_class=nil)
    options = { target: '_blank', class: css_class }
    link_to((text || courses_user.user.username), courses_user.contribution_url, options)
  end

  def course_role_name(courses_users_role)
    case courses_users_role
    when CoursesUsers::Roles::STUDENT_ROLE
      return t('users.role.student')
    when CoursesUsers::Roles::INSTRUCTOR_ROLE
      return t('users.role.instructor')
    when CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE
      return t('users.role.campus_volunteer')
    when CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE
      return t('users.role.online_volunteer')
    when CoursesUsers::Roles::WIKI_ED_STAFF_ROLE
      return t('users.role.wiki_ed_staff')
    end
  end
end
