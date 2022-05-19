# frozen_string_literal: true

json.all_courses @courses.includes(:wikis, :home_wiki,
                                   :students, :instructors, :campaigns) do |course|
  json.call(course, :id, :slug, :title, :institution, :term, :created_at, :start, :end)
  json.home_wiki course.home_wiki.domain
  json.tracked_wikis course.wikis.map(&:domain)
  json.facilitators course.instructors.pluck(:username)
  json.editors course.students.pluck(:username)
  json.campaign_slugs course.campaigns.pluck(:slug)
end
