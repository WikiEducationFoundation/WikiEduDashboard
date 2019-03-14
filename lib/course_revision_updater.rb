# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/importers/revision_importer"

#= Fetches and imports new revisions for courses
class CourseRevisionUpdater
  ###############
  # Entry point #
  ###############
  def self.import_new_revisions(course)
    return if course.students.empty?
    new(course).update_revisions_for_relevant_wikis
    ArticlesCourses.update_from_course(course)
  end

  def initialize(course)
    @course = course
  end

  def default_wiki_ids
    wiki_ids = [@course.home_wiki.id]
    # For Programs & Events Dashboard, pull in Wikidata edits by default for all
    # courses.
    wiki_ids << Wiki.get_or_create(language: nil, project: 'wikidata').id unless Features.wiki_ed?
    wiki_ids
  end

  def update_revisions_for_relevant_wikis
    wiki_ids = @course.assignments.pluck(:wiki_id) + default_wiki_ids
    wiki_ids.uniq.each do |wiki_id|
      RevisionImporter.new(Wiki.find(wiki_id), @course).import_new_revisions_for_course
    end
  end
end
