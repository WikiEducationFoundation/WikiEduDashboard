# frozen_string_literal: true

#= Helpers for rendering course data in student view
# An instructor can preview their course page as an enrolled student sees it.
# While that's on, the course page requests its course and users data with
# view_as=student, and these methods render it for a student instead. The
# param can only lower the role used for rendering, never raise it.
module StudentViewHelper
  def student_view?
    params[:view_as] == 'student'
  end

  def viewer_role(course)
    role = current_user&.highest_role(course) || CoursesUsers::Roles::VISITOR_ROLE
    return role unless student_view?
    [role, CoursesUsers::Roles::STUDENT_ROLE].min
  end

  def viewer_sees_real_names?(course)
    return false if student_view?
    user_signed_in? && current_user.can_see_real_names?(course)
  end
end
