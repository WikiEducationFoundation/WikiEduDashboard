# frozen_string_literal: true

if @campaign
  json.campaign do
    json.id @campaign.id
    json.title @campaign.title
    json.slug @campaign.slug
    json.description @campaign.description
    json.template_description @campaign.template_description
    json.default_course_type @campaign.default_course_type
    json.default_passcode @campaign.default_passcode
    json.courses_count @presenter.courses.count  
  end
end
