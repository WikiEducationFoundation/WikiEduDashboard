class CourseSubmissionMailerPreview < ActionMailer::Preview
  def submission
    CourseSubmissionMailer.submission(Course.last, User.last)
  end
end
