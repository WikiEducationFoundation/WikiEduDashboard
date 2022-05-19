# frozen_string_literal: true

json.all_campaigns @campaigns.includes(:organizers) do |campaign|
  json.call(campaign, :id, :title, :slug, :description, :created_at)
  json.organizers campaign.organizers.pluck(:username)
end
