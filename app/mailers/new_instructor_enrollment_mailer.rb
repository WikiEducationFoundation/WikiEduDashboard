# frozen_string_literal: true

class NewInstructorEnrollmentMailer < ApplicationMailer
  def self.send_staff_alert(course:, adder:, new_instructor:)
    return unless Features.email?
    staffer = User.find_by(username: ENV['classroom_program_manager'])
    email(course, staffer, adder, new_instructor).deliver_now
  end

  def email(course, staffer, adder, new_instructor)
    @course = course
    @new_instructor = new_instructor
    @adder = adder
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    mail(to: staffer.email,
         reply_to: adder.email,
         subject: "New instructor added for #{@course.slug}")
  end
end
