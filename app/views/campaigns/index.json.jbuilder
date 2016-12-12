# frozen_string_literal: true
if @campaign
  json.campaign do
    json.id @campaign.id
    json.title @campaign.title
    json.slug @campaign.slug
  end
end
