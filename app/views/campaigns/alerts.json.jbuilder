# frozen_string_literal: true

json.alerts @campaign.alerts do |alert|
  json.id alert.id
  json.type alert.type
  json.user User.find_by(id: alert.user_id).username if alert.user_id
  json.course Course.find_by(id: alert.course_id).title if alert.course_id
  json.article Article.find_by(id: alert.article_id).title if alert.article_id
end
