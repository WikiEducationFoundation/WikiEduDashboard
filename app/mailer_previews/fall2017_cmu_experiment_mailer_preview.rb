# frozen_string_literal: true

class Fall2017CmuExperimentMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Emails for the Fall 2017 CMU experiment to invite or remind instructors.'
  METHOD_DESCRIPTIONS = {
    invite_instructor: 'Initial invitation to a CMU instructor to opt into the experiment',
    remind_instructor: 'Follow-up reminder to a CMU instructor who has not yet responded'
  }.freeze

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
      id: 99
    )
  end

  def instructor
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end

  def email_passcode
    'abcde1234'
  end
end
