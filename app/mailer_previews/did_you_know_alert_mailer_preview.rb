# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class DidYouKnowAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = "Sent to instructors when a student's article is nominated for Did You Know."
  METHOD_DESCRIPTIONS = {
    message_to_instructors: "Notifies instructors of a student's DYK nomination"
  }.freeze
  RECIPIENTS = 'instructor(s), Wiki Expert'

  def message_to_instructors
    DidYouKnowAlertMailer.email(example_alert)
  end

  private

  def example_alert
    Alert.new(type: 'DYKNominationAlert',
              article: Article.new(title: 'Climate_change_mitigation',
                                   wiki: Wiki.default_wiki, namespace: 0),
              course: example_course)
  end
end
