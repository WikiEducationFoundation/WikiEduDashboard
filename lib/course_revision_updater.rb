# frozen_string_literal: true

require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/lib/replica"

#= Fetches and imports new revisions for courses
class CourseRevisionUpdater
  ###############
  # Entry point #
  ###############

  def self.import_new_revisions_concurrently(courses)
    # Revision data is imported via Replica, and its capacity may be the
    # bottleneck in this process.
    concurrency = Replica::CONCURRENCY_LIMIT
    course_groups = courses.to_a.in_groups(concurrency, false)
    threads = course_groups.map.with_index do |course_group, i|
      Thread.new(i) do
        import_new_revisions(course_group)
      end
    end
    threads.each(&:join)
  end

  def self.import_new_revisions(courses)
    courses.each do |course|
      next if course.students.empty?
      new(course).update_revisions_for_relevant_wikis
      ArticlesCourses.update_from_course(course)
    end
  end

  def initialize(course)
    @course = course
  end

  def default_wiki_ids
    wiki_ids = [@course.home_wiki.id]
    # For Programs & Events Dashboard, pull in Wikidata edits by default for all
    # courses.
    unless Features.wiki_ed?
      wiki_ids << Wiki.get_or_create(language: nil, project: 'wikidata').id
    end
    wiki_ids
  end

  def update_revisions_for_relevant_wikis
    wiki_ids = @course.assignments.pluck(:wiki_id) + default_wiki_ids
    wiki_ids.uniq.each do |wiki_id|
      RevisionImporter.new(Wiki.find(wiki_id), @course).import_new_revisions_for_course
    end
  end
end
