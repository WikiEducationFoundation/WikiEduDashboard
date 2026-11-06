# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class PreexistingAiTextAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = '[PLACEHOLDER - description of the pre-existing AI text alert for the ' \
                'mailer previews page]'
  METHOD_RECIPIENTS = {
    email: 'student, instructor(s), Wiki Expert'
  }.freeze

  def email
    PreexistingAiTextAlertMailer.email(example_alert)
  end

  private

  def example_alert
    article = Article.new(title: 'Kingdom of Aksum', wiki: Wiki.default_wiki, namespace: 0)
    PreexistingAiTextAlert.new(
      course: example_course,
      user: User.new(username: 'Sage (Wiki Ed)', email: 'sage@example.com', permissions: 3),
      article:, revision_id: 1382181955,
      details: { article_title: article.full_title, origin_edits: example_origin_edits }
    )
  end

  def example_origin_edits
    [{ rev_id: 1232032584, username: 'Danial Bass', timestamp: '2024-07-01T15:43:21Z',
       words: 49, max_ai_likelihood: 0.99, flagged: true, already_alerted: false,
       pangram_share_link: 'https://www.pangram.com/history/88ba317f-8572-4000-911f-2aa8fbea68fa' },
     { rev_id: 1192042271, username: 'Socialwave597', timestamp: '2023-12-27T08:28:09Z',
       words: 29, max_ai_likelihood: 0.02, flagged: false, already_alerted: false,
       pangram_share_link: 'https://www.pangram.com/history/88ba317f-8572-4000-911f-2aa8fbea68fa' }]
  end
end
