# frozen_string_literal: true

json.course do
  json.partial! 'courses/campaigns', course: @course
  json.published CampaignsCourses.exists?(course_id: @course.id)
end
