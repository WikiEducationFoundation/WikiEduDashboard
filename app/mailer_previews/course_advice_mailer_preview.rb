# frozen_string_literal: true

class CourseAdviceMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Advice emails sent to instructors by Wiki Ed staff at key stages of their course.'
  METHOD_DESCRIPTIONS = {
    biographies: 'Advice for instructors whose students are working on biography articles',
    hype_video: 'Advice including a link to the Wiki Ed hype video for instructor motivation',
    generative_ai: 'Guidance on addressing generative AI use in student Wikipedia editing',
    preliminary_work: 'Tips on preliminary work students should do before editing Wikipedia',
    choosing_an_article: 'Advice on helping students choose appropriate Wikipedia articles',
    bibliographies: 'Guidance on how students should use and cite bibliographies',
    drafting_and_moving: 'Advice on drafting in sandboxes and moving articles to mainspace',
    drafting_sandbox_only: 'Drafting advice for sandbox-only courses that never move to mainspace',
    peer_review: 'Tips on facilitating peer review between students',
    assessing_contributions: 'Guidance on how to assess student Wikipedia contributions'
  }.freeze

  def biographies
    CourseAdviceMailer.email(example_course, 'biographies', example_staffer)
  end

  def hype_video
    CourseAdviceMailer.email(example_course, 'hype_video', example_staffer)
  end

  def generative_ai
    CourseAdviceMailer.email(example_course, 'generative_ai', example_staffer)
  end

  def preliminary_work
    CourseAdviceMailer.email(example_course, 'preliminary_work', example_staffer)
  end

  def choosing_an_article
    CourseAdviceMailer.email(example_course, 'choosing_an_article', example_staffer)
  end

  def bibliographies
    CourseAdviceMailer.email(example_course, 'bibliographies', example_staffer)
  end

  def drafting_and_moving
    CourseAdviceMailer.email(example_course, 'drafting_and_moving', example_staffer)
  end

  def drafting_sandbox_only
    CourseAdviceMailer.email(sandbox_only_course, 'drafting_and_moving', example_staffer)
  end

  def peer_review
    CourseAdviceMailer.email(example_course, 'peer_review', example_staffer)
  end

  def assessing_contributions
    CourseAdviceMailer.email(example_course, 'assessing_contributions', example_staffer)
  end

  private

  def example_course
    Course.new(
      title: 'Advanced Topics in Global Health',
      slug: 'Global_Health/Advanced_Topics_(Spring_2025)',
      school: 'University of Maryland',
      expected_students: 24,
      user_count: 22,
      start: 3.months.ago,
      end: 1.month.from_now,
      revision_count: 450
    )
  end

  def sandbox_only_course
    course = example_course
    course.define_singleton_method(:stay_in_sandbox?) { true }
    course
  end

  def example_staffer
    User.new(email: 'sage@example.com', username: 'Sage (Wiki Ed)', real_name: 'Sage Ross')
  end
end
