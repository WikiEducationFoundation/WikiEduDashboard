# frozen_string_literal: true

class ActiveCourseMailer < ApplicationMailer
  def self.send_active_course_email(course, instructor)
    return unless Features.email?
    return if instructor.email.nil?
    email(course, instructor).deliver_now
  end

  def email(course, instructor)
    @course = course
    @instructor = instructor
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @articles_link = "#{@course_link}/articles"
    mail(to: @instructor.email, subject: 'Check out what your students have done on Wikipedia!')
  end
end
