class CourseSubmissionMailer < ApplicationMailer
  def submission(course, instructor)
    @course = course
    @instructor = instructor
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    mail(to: @instructor.email, subject: 'Thanks for submitting your course!')
  end
end
