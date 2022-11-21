# frozen_string_literal: true

module SurveysUrlHelper
  def course_survey_url(notification)
    slug = notification.course.slug.gsub('&', '%26')
    "https://#{survey_url(notification.survey)}?course_slug=#{slug}"
  end
end
