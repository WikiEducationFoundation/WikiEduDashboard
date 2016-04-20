class CourseSubmissionMailerPreview < ActionMailer::Preview
  def submission
    CourseSubmissionMailer.email(Course.last, User.last)
  end
end
