# frozen_string_literal: true

class DidYouKnowAlertMailerPreview < ActionMailer::Preview
  DESCRIPTION = "Sent to instructors when a student's article is nominated for Did You Know."
  METHOD_DESCRIPTIONS = {
    message_to_instructors: "Notifies instructors of a student's DYK nomination"
  }.freeze

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
end
