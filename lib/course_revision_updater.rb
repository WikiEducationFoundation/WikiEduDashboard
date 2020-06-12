# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/importers/revision_importer"

#= Fetches and imports new revisions for courses
class CourseRevisionUpdater
  ###############
  # Entry point #
  ###############
  def self.import_revisions(course, all_time:, update_cs: nil)
    course = course
    return if course.students.empty?
    new(course, update_cs: update_cs).update_revisions_for_relevant_wikis(all_time)
    ArticlesCourses.update_from_course(course)
  end

  def initialize(course, update_cs: nil)
    @course = course
    @update_cs = update_cs
  end

  def update_revisions_for_relevant_wikis(all_time)
    @course.wikis.each do |wiki|
      RevisionImporter.new(wiki, @course, update_cs: @update_cs)
                      .import_revisions_for_course(all_time: all_time)
    end
  end
end
