# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/mentorship_csv_builder"

# Instructors of campaign courses tagged 'mentor_requested', which the
# assignment wizard's mentorship panel applies when a first-time instructor
# asks to be matched with a mentor.
class MentorRequestsCsvBuilder < MentorshipCsvBuilder
  MENTOR_REQUESTED_TAG = 'mentor_requested'

  private

  def rows
    tagged_courses.flat_map do |course|
      instructors(course).map do |courses_user|
        row(courses_user.user, course, courses_user.real_name)
      end
    end
  end

  def tagged_courses
    @campaign.courses.where(id: Tag.courses_tagged_with(MENTOR_REQUESTED_TAG))
  end

  def instructors(course)
    course.courses_users.includes(:user).where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end
end
