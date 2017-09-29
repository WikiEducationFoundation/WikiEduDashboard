# frozen_string_literal: true

json.campaigns @course.campaigns do |campaign_course|
  json.call(campaign_course, :id, :title, :slug)
end
