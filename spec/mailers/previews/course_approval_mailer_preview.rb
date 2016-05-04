class CourseApprovalMailerPreview < ActionMailer::Preview
  def approval
    CourseApprovalMailer.email(Course.last, User.last)
  end
end
