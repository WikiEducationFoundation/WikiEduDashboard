# frozen_string_literal: true

namespace :courses_wikis do
  desc 'Creates CoursesWikis association for existing courses through revisions'
  task migrate: :environment do
    Rails.logger.debug 'Creating CoursesWikis associations'
    default_wiki_id = if Features.wiki_ed?
                        []
                      else
                        [Wiki.get_or_create(language: nil, project: 'wikidata').id]
                      end

    Course.all.each do |course|
      # The Course#wiki_ids method is removed
      # and hence its contents is used here.
      wiki_ids = [course.home_wiki_id] + [default_wiki_id] + course.assignments.pluck(:wiki_id)
      course.update(wikis: Wiki.find(wiki_ids))
    end
  end
end
