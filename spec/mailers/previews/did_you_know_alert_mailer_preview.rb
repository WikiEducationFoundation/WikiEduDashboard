# frozen_string_literal: true

class DidYouKnowAlertMailerPreview < ActionMailer::Preview
  def message_to_instructors
    dyk_nomination_alert = Alert.find_by(type: 'DYKNominationAlert')
    unless dyk_nomination_alert.present?
      article_course = ArticlesCourses.last
      dyk_nomination_alert = Alert.create!(type: 'DYKNominationAlert',
                                           article_id: article_course.article_id,
                                           course_id: article_course.course_id)
    end
    DidYouKnowAlertMailer.email(dyk_nomination_alert)
  end
end
