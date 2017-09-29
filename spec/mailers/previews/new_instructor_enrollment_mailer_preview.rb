# frozen_string_literal: true

class NewInstructorEnrollmentMailerPreview < ActionMailer::Preview
  def alert_staff
    NewInstructorEnrollmentMailer.email(course, staffer, adder, new_instructor)
  end

  private

  def course
    Course.new(
      slug: 'Example_University/Example_Course_(term)'
    )
  end

  def staffer
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end

  def adder
    User.new(username: 'First Instructor')
  end

  def new_instructor
    User.new(username: 'New Instructor')
  end
end
