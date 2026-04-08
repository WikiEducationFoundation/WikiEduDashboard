# frozen_string_literal: true

class NewInstructorEnrollmentMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent to Wiki Ed staff when a new co-instructor is added to an existing course.'
  METHOD_DESCRIPTIONS = {
    alert_staff: 'Staff notification when a second instructor joins a course already in progress'
  }.freeze
  RECIPIENTS = 'staff'

  def alert_staff
    NewInstructorEnrollmentMailer.email(course, staffer, adder, new_instructor, courses_user)
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

  def courses_user
    OpenStruct.new(real_name: 'Alice Bob', role_description: 'Teaches Wikipedia basics')
  end
end
