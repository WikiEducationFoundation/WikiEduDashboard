# frozen_string_literal: true

# This can be run in the rails console to get a CSV for each campaign

require 'csv'

Campaign.all.each do |campaign|
  CSV.open("/root/#{campaign.slug}.csv", 'wb') do |csv|
    csv << %w[course_slug students characters_added]
    campaign.courses.each do |course|
      csv << [course.slug, course.students.count, course.character_sum]
    end
  end
end
