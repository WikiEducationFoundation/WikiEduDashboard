# frozen_string_literal: true

json.campaigns @campaigns do |campaign|
  json.call(campaign, :id, :title, :slug, :description)
end
json.total_pages @total_pages
json.current_page @page
