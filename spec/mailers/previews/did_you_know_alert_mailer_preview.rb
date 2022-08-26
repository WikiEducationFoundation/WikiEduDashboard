# frozen_string_literal: true

class DidYouKnowAlertMailerPreview < ActionMailer::Preview
  def message_to_instructors
    DidYouKnowAlertMailer.email(example_alert)
  end

  private

  def example_alert
    Alert.new(type: 'DYKNominationAlert',
              article: Article.last,
              course: Course.nonprivate.last)
  end
end
