# frozen_string_literal: true

class HighQualityArticleAssignmentMailerPreview < ActionMailer::Preview
  def message_to_student_and_instructors
    dyk_nomination_alert = Alert.find_by(type: 'HighQualityArticleAssignmentAlert')
    unless dyk_nomination_alert.present?
      article_course = ArticlesCourses.last
      dyk_nomination_alert = Alert.create!(type: 'HighQualityArticleAssignmentAlert',
                                           article_id: article_course.article_id,
                                           user_id: User.last.id,
                                           course_id: article_course.course_id)
    end
    HighQualityArticleAssignmentMailer.email(dyk_nomination_alert)
  end
end
