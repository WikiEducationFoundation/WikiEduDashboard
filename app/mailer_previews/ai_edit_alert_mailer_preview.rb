# frozen_string_literal: true

class AiEditAlertMailerPreview < ActionMailer::Preview
  DESCRIPTION = "Sent when AI content is detected in a student's or scholar's Wikipedia edit."
  METHOD_DESCRIPTIONS = {
    student_program_ai_edit_alert_mainspace:
      'Alert for a student program edit to a live Wikipedia article',
    student_program_ai_edit_alert_exercise:
      'Alert for a course exercise page edit (/Outline suffix)',
    student_program_ai_edit_alert_sandbox_draft:
      'Alert for an edit to a user sandbox or draft page',
    scholars_program_ai_edit_alert:
      'Alert for a Wikipedia Fellows scholar (non-ClassroomProgram)',
    instructor_guidance_for_first_alert:
      'Guidance sent to instructors when their first AI alert fires'
  }.freeze

  def student_program_ai_edit_alert_mainspace
    AiEditAlertMailer.email(example_student_program_alert(mainspace_page))
  end

  def student_program_ai_edit_alert_exercise
    AiEditAlertMailer.email(example_student_program_alert(exercise_page))
  end

  def student_program_ai_edit_alert_sandbox_draft
    AiEditAlertMailer.email(example_student_program_alert(sandbox_draft_page))
  end

  def scholars_program_ai_edit_alert
    AiEditAlertMailer.email(example_scholars_alert)
  end

  def instructor_guidance_for_first_alert
    AiEditAlertMailer.instructor_advice_email(example_student_program_alert(exercise_page))
  end

  private

  def example_alert_details(title)
    { article_title: title,
      pangram_prediction: 'We are confident that this document is fully AI-generated',
      headline_result: 'Fully AI Generated',
      average_ai_likelihood: 0.974378,
      max_ai_likelihood: 1.0,
      fraction_human_content: 0.0,
      fraction_ai_content: 1.0,
      fraction_mixed_content: 0.0,
      window_likelihoods: [1.0, 0.9982278487261604, 0.9959831237792969],
      predicted_ai_window_count: 3,
      pangram_share_link: 'https://www.pangram.com/history/88ba317f-8572-4000-911f-2aa8fbea68fa',
      pangram_version: '3.0',
      prior_alert_count_for_course: 0 }
  end

  def example_user
    User.new(username: 'Sage (Wiki Ed)', email: 'sage@example.com', permissions: 3)
  end

  def example_course
    course = Course.new(
      title: 'Advanced Topics in Global Health',
      slug: 'Global_Health/Advanced_Topics_(Spring_2025)',
      school: 'University of Maryland',
      expected_students: 24,
      user_count: 22,
      start: 3.months.ago,
      end: 1.month.from_now,
      revision_count: 450
    )
    instructor = example_user
    course.define_singleton_method(:instructors) { [instructor] }
    course
  end

  def example_student_program_alert(article)
    AiEditAlert.new(
      course: example_course,
      user: example_user,
      article: article,
      revision_id: 1127999373,
      details: example_alert_details(article.full_title)
    )
  end

  def exercise_page
    Article.new(title: 'Ragesoss/Artwork title/Outline', wiki: Wiki.default_wiki, namespace: 2)
  end

  def sandbox_draft_page
    Article.new(title: 'Ragesoss/Artwork title', wiki: Wiki.default_wiki, namespace: 2)
  end

  def mainspace_page
    Article.new(title: 'Artwork title', wiki: Wiki.default_wiki, namespace: 0)
  end

  def example_scholars_alert
    article = mainspace_page
    AiEditAlert.new(
      course: FellowsCohort.new(title: 'Wikipedia Fellows Cohort 2024'),
      user: example_user,
      article: article,
      revision_id: 1127999373,
      details: example_alert_details(article.full_title)
    )
  end
end
