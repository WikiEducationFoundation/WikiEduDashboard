module SurveyAssignmentsHelper
  ROLES = [
    {
      name: 'Instructors',
      role: CoursesUsers::Roles::INSTRUCTOR_ROLE
    },
    {
      name: 'Students', 
      role: CoursesUsers::Roles::STUDENT_ROLE
    }
  ]

  def notification_schedule_summary(survey_assignment)
    days = survey_assignment.send_date_days
    before = survey_assignment.send_before ? "Before" : "After"
    relative_to = survey_assignment.send_date_relative_to
    "#{days} Days #{before} #{relative_to}"
  end

  def user_role_select(f)
    f.select :courses_user_role, options_for_select(ROLES.collect {|r| [r.values[0], r.values[1]]}, 1), {}, {:data => { :chosen_select => true}}
  end

  def user_role(survey_assignment)
    ROLES.select { |r| r[:role] == survey_assignment.courses_user_role }.first[:name]
  end
end
