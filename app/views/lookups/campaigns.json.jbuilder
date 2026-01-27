json.campaigns @values do |campaign|
  json.call(campaign, :id, :title, :slug)
  json.courses campaign.courses.count
end
