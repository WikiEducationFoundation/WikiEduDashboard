# frozen_string_literal: true
json.courses @courses do |course|
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
