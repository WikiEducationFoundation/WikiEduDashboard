# frozen_string_literal: true

if @user.course_instructor?
  json.as_instructor do
    json.course_string_prefix @courses_presenter.course_string_prefix
    json.courses_count @courses_presenter.courses.count
    json.user_count @courses_presenter.user_count
    json.trained_percent number_to_human @courses_presenter.trained_percent
  end

  json.by_students do
    json.word_count number_to_human @courses_presenter.word_count
    json.view_sum number_to_human @courses_presenter.courses.sum(:view_sum)
    json.article_count number_to_human @courses_presenter.courses.sum(:article_count)
    json.new_article_count number_to_human @courses_presenter.courses.sum(:new_article_count)
    json.upload_count number_to_human @courses_presenter.courses.sum(:upload_count)
    json.uploads_in_use_count @courses_presenter.uploads_in_use_count
    json.upload_usage_count @courses_presenter.upload_usage_count
  end
end

if @user.course_student?
  json.as_student do
    json.course_string_prefix @individual_stats_presenter.course_string_prefix
    json.individual_courses_count @individual_stats_presenter.individual_courses.count
    json.individual_word_count number_to_human @individual_stats_presenter.individual_word_count
    json.individual_article_views number_to_human @individual_stats_presenter.individual_article_views
    json.individual_article_count number_to_human @individual_stats_presenter.individual_article_count
    json.individual_articles_created number_to_human @individual_stats_presenter.individual_articles_created
    json.individual_upload_count number_to_human @individual_stats_presenter.individual_upload_count
    json.individual_upload_usage_count number_to_human @individual_stats_presenter.individual_upload_usage_count
  end
end
