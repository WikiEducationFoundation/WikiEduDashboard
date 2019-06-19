# frozen_string_literal: true

namespace :courses_wikis do
  desc 'Creates CoursesWikis association for existing courses through revisions'
  task migrate: :environment do
    Rails.logger.debug 'Creating CoursesWikis associations'
    Course.all.each do |course|
      course.wikis.push(Wiki.find(course.wiki_ids))
    end
  end
end
