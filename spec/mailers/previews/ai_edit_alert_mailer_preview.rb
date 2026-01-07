# frozen_string_literal: true

class AiEditAlertMailerPreview < ActionMailer::Preview
  def student_program_ai_edit_alert
    AiEditAlertMailer.email(example_student_program_alert)
  end

  def scholars_program_ai_edit_alert
    AiEditAlertMailer.email(example_scholars_alert)
  end

  private

  def example_alert_details
    { article_title: 'Artwork title',
      pangram_prediction: 'Fully AI-Generated',
      headline_result: 'AI Detected',
      average_ai_likelihood: 1.0,
      max_ai_likelihood: 1.0,
      fraction_human_content: 0.0,
      fraction_ai_content: 1.0,
      fraction_mixed_content: 0.0,
      window_likelihoods: [1.0, 1.0],
      predicted_ai_window_count: 2,
      pangram_share_link: 'https://www.pangram.com/history/88ba317f-8572-4000-911f-2aa8fbea68fa',
      pangram_version: 'adaptive_boundaries' }
  end

  def example_student_program_alert
    AiEditAlert.new(
      course: Course.last,
      user: User.where(permissions: 3).first,
      article: Article.new(title: 'Artwork title', wiki: Wiki.default_wiki, namespace: 0),
      revision_id: 1127999373,
      details: example_alert_details
    )
  end

  def example_scholars_alert
    AiEditAlert.new(
      course: FellowsCohort.last,
      user: User.where(permissions: 3).first,
      article: Article.new(title: 'Artwork title', wiki: Wiki.default_wiki, namespace: 0),
      revision_id: 1127999373,
      details: example_alert_details
    )
  end
end
