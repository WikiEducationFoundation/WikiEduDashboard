# frozen_string_literal: true

module SurveysUrlHelper
  def course_survey_url(notification)
    "#{survey_url(notification.survey)}?course_slug=#{notification.course.slug}"
  end
end
