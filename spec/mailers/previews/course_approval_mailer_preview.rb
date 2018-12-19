# frozen_string_literal: true

class CourseApprovalMailerPreview < ActionMailer::Preview
  def returning_instructor_approval
    CourseApprovalMailer.email(example_returning_course, example_user)
  end

  def new_instructor_approval
    CourseApprovalMailer.email(example_course, example_user)
  end

  private

  def example_course
    Course.new(
      school: 'Example University',
      title: 'Example Course',
      term: 'Fall 2019',
      slug: 'Example_University/Example_Course_(Fall_2019)',
      passcode: 'abcdefg'
    )
  end

  def example_returning_course
    course = example_course
    course.define_singleton_method(:tag?) do |tag|
      tag == 'returning_instructor'
    end
    course
  end

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss', real_name: 'Sage Ross')
  end
end
