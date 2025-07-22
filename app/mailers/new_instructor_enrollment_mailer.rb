# frozen_string_literal: true

class NewInstructorEnrollmentMailer < ApplicationMailer
  def self.send_staff_alert(course:, adder:, new_instructor:)
    return unless Features.email?
    staffer = SpecialUsers.classroom_program_manager
    return unless staffer
    courses_user = CoursesUsers.find_by(course: @course, user: @new_instructor,
                                        role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    email(course, staffer, adder, new_instructor, courses_user).deliver_now
  end

  def email(course, staffer, adder, new_instructor, courses_user)
    @course = course
    @new_instructor = new_instructor
    @courses_user = courses_user
    @adder = adder
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    mail(to: staffer.email,
         reply_to: adder.email,
         subject: "New instructor added for #{@course.slug}")
  end
end
