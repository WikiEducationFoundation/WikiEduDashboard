# frozen_string_literal: true

json.campaigns @values do |campaign|
  json.call(campaign, :id, :title, :slug)
end
