# frozen_string_literal: true

json.campaigns @values do |campaign|
  json.call(campaign, :id, :title, :slug)
end
json.total_pages @total_pages if @total_pages
json.current_page @page if @page
