# frozen_string_literal: true

class Fall2017CmuExperimentMailerPreview < ActionMailer::Preview
  def invite_instructor
    Fall2017CmuExperimentMailer.email(course, instructor, email_passcode)
  end

  def remind_instructor
    Fall2017CmuExperimentMailer.email(course, instructor, email_passcode, reminder: true)
  end

  private

  def course
    Course.new(
      slug: 'Example_University/Example_Course_(term)',
      id: Course.first.id
    )
  end

  def instructor
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end

  def email_passcode
    'abcde1234'
  end
end
