# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/importers/revision_importer"

#= Fetches and imports new revisions for courses
class CourseRevisionUpdater
  ###############
  # Entry point #
  ###############
  def self.import_revisions(update_cs, all_time:)
    course = update_cs.course
    return if course.students.empty?
    new(update_cs).update_revisions_for_relevant_wikis(all_time)
    ArticlesCourses.update_from_course(course)
  end

  def initialize(update_cs)
    @update_cs = update_cs
    @course = update_cs.course
  end

  def update_revisions_for_relevant_wikis(all_time)
    @course.wikis.each do |wiki|
      RevisionImporter.new(wiki, @update_cs)
                      .import_revisions_for_course(all_time: all_time)
    end
  end
end
