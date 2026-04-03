# frozen_string_literal: true

class CourseApprovalMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent to instructors when their course application is approved by Wiki Education staff.' # rubocop:disable Layout/LineLength
  METHOD_DESCRIPTIONS = {
    returning_instructor_approval: 'Course approval (returning instructor)',
    new_instructor_approval: 'Course approval (first-time instructor)',
    new_sandbox_approval: 'Course approval (stay-in-sandbox course, first-time instructor)',
    returning_sandbox_approval: 'Course approval (stay-in-sandbox course, returning instructor)'
  }.freeze
  RECIPIENTS = 'instructor(s)'

  def returning_instructor_approval
    CourseApprovalMailer.email(example_returning_course, example_user)
  end

  def new_instructor_approval
    CourseApprovalMailer.email(example_course, example_user)
  end

  def new_sandbox_approval
    CourseApprovalMailer.email(example_new_sandbox_course, example_user)
  end

  def returning_sandbox_approval
    CourseApprovalMailer.email(example_returning_sandbox_course, example_user)
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

  def example_returning_sandbox_course
    course = example_course
    course.define_singleton_method(:tag?) do |tag|
      tag == 'returning_instructor'
    end
    course.define_singleton_method(:stay_in_sandbox?) do
      true
    end
    course
  end

  def example_new_sandbox_course
    course = example_course
    course.define_singleton_method(:stay_in_sandbox?) do
      true
    end
    course
  end

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss', real_name: 'Sage Ross')
  end
end
