class CourseSubmissionMailer < ApplicationMailer
  def send_submission_confirmation(course, instructor)
    return unless Features.email?
    return if instructor.email.nil?
    @course = course
    @instructor = instructor
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    mail(to: @instructor.email, subject: 'Thanks for submitting your course!').deliver_now
  end
end
