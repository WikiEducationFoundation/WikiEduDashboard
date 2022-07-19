# frozen_string_literal: true
json.courses @presenter.courses do |course|
  json.cache! [locale, course], expires_in: 1.day do
    json.call(
      course,
      :id,
      :title,
      :slug,
      :description,
      :school,
      :term,
      :word_count,
      :recent_revision_count,
      :references_count,
      :view_sum,
      :user_count,
      :average_word_count,
      :trained_count
    )
    json.human_references_count number_to_human(course.references_count)
    json.human_word_count number_to_human(course.word_count)
    json.human_view_sum number_to_human(course.view_sum)
    json.creation_date I18n.l course.created_at.to_date
    json.instructor course.courses_users.where(role: 1).first&.real_name
    json.human_average_word_count number_to_human(course.average_word_count)
  end
end

json.statistics do
  json.courses_count number_to_human @presenter.courses.count
  json.user_count number_to_human @presenter.user_count
  json.new_article_count_human number_to_human(@presenter.courses.sum(:new_article_count))
  json.word_count_human number_to_human(@presenter.word_count)
  json.references_count_human number_to_human(@presenter.references_count)
  json.view_sum_human number_to_human(@presenter.courses.sum(:view_sum))
  json.article_count_human number_to_human(@presenter.courses.sum(:article_count))
  json.upload_count_human number_to_human(@presenter.courses.sum(:upload_count))
  json.uploads_in_use_count_human number_to_human(@presenter.uploads_in_use_count)
  json.uploads_in_use_count @presenter.uploads_in_use_count
  json.upload_usage_count_human number_to_human(@presenter.upload_usage_count)
  json.upload_usage_count @presenter.upload_usage_count
  json.trained_percent_human number_to_human(@presenter.trained_percent)
end

json.wiki_domain @wiki.domain
