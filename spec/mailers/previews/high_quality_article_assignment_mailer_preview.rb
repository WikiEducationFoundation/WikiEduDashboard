# frozen_string_literal: true

class HighQualityArticleAssignmentMailerPreview < ActionMailer::Preview
  def message_to_student_and_instructors
    HighQualityArticleAssignmentMailer.email(example_alert)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end

  def example_alert
    Alert.new(type: 'HighQualityArticleAssignmentAlert',
              article: Article.last,
              user: example_user,
              course: Course.nonprivate.last)
  end
end
