# frozen_string_literal: true

class CourseAdviceMailerPreview < ActionMailer::Preview
  def preliminary_work
    CourseAdviceMailer.email(example_course, 'preliminary_work', example_staffer)
  end

  def drafting_and_moving
    CourseAdviceMailer.email(example_course, 'drafting_and_moving', example_staffer)
  end

  def peer_review
    CourseAdviceMailer.email(example_course, 'peer_review', example_staffer)
  end

  def assessing_contributions
    CourseAdviceMailer.email(example_course, 'assessing_contributions', example_staffer)
  end

  private

  def example_course
    Course.last
  end

  def example_staffer
    User.new(email: 'sage@example.com', username: 'Sage (Wiki Ed)', real_name: 'Sage Ross')
  end
end
