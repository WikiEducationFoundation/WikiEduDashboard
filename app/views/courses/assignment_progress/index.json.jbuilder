# frozen_string_literal: true

show_real_names = current_user.can_see_real_names?(@course)

json.students @presenter.students do |user|
  json.call(user, :id, :username)
  json.real_name user.real_name if show_real_names
end

json.items @presenter.items do |item|
  json.call(item, :key, :kind)
  json.title item.title if item.title
  json.article_stage item.article_stage if item.article_stage
  json.due_date item.due_date if item.due_date
  json.merge! @presenter.links_for(item)
end

json.summary @presenter.summary
json.article_statuses @presenter.article_statuses

if @item
  json.item_key @item.key
  json.rows @presenter.rows_for(@item)
end
