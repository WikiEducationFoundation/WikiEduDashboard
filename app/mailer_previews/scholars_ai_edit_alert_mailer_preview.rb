# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class ScholarsAiEditAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent when AI content is detected in a Wikipedia Fellows scholar edit.'
  METHOD_DESCRIPTIONS = {
    scholars_program_ai_edit_alert:
      'Alert for a Wikipedia Fellows scholar (non-ClassroomProgram course)'
  }.freeze
  RECIPIENTS = 'scholar, Wiki Expert'

  def scholars_program_ai_edit_alert
    AiEditAlertMailer.email(example_scholars_alert)
  end

  private

  def example_scholars_alert
    article = Article.new(title: 'Artwork title', wiki: Wiki.default_wiki, namespace: 0)
    AiEditAlert.new(
      course: FellowsCohort.new(title: 'Wikipedia Fellows Cohort 2024'),
      user: example_instructor,
      article: article,
      revision_id: 1127999373,
      details: example_alert_details(article.full_title)
    )
  end

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
end
