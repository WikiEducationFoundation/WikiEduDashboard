# frozen_string_literal: true

if @tag
  json.stats do
    json.title @tag
    json.slug @tag
    json.courses_count number_to_human @presenter.courses.count
    json.user_count number_to_human @presenter.user_count
    json.word_count_human number_to_human(@presenter.word_count)
    json.references_count_human number_to_human(@presenter.references_count)
    json.view_sum_human number_to_human(@presenter.courses.sum(:view_sum))
    json.article_count_human number_to_human(@presenter.courses.sum(:article_count))
    json.new_article_count_human number_to_human(@presenter.courses.sum(:new_article_count))
    json.upload_count_human number_to_human(@presenter.courses.sum(:upload_count))
    json.course_string_prefix @presenter.course_string_prefix
    json.trained_percent_human number_to_human(@presenter.trained_percent)
    json.uploads_in_use_count @presenter.uploads_in_use_count
    json.upload_usage_count @presenter.upload_usage_count
  end
end
