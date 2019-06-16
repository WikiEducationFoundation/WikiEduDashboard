# frozen_string_literal: true

namespace :courses_wikis do
  desc 'Creates CoursesWikis association for existing courses through revisions'
  task migrate: :environment do
    Rails.logger.debug 'Creating CoursesWikis associations'
    Course.all.each do |course|
      home_wiki_id = course.home_wiki.id # Home Wiki is already tracked
      wiki_ids = course.revisions.pluck(Arel.sql('DISTINCT wiki_id')).uniq - [home_wiki_id]
      course.wikis.push(Wiki.find(wiki_ids))
    end
  end
end
