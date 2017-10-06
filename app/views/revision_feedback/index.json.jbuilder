# frozen_string_literal: true

json.rating @rating
json.suggestions @feedback do |message|
  json.message message
end
json.custom @user_feedback do |feedback|
  json.message feedback.text
  json.messageId feedback.id
  json.userId feedback.user_id
end
