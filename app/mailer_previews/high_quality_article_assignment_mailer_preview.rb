# frozen_string_literal: true

class HighQualityArticleAssignmentMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent when a student is assigned a Good Article or Featured Article.'
  METHOD_DESCRIPTIONS = {
    message_to_student_and_instructors:
      'Warns that the assigned article is already high quality'
  }.freeze

  def message_to_student_and_instructors
    HighQualityArticleAssignmentMailer.email(example_alert)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end

  def example_alert
    Alert.new(type: 'HighQualityArticleAssignmentAlert',
              article: Article.new(title: 'Climate_change_mitigation',
                                   wiki: Wiki.default_wiki, namespace: 0),
              user: example_user,
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
