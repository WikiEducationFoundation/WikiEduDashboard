# frozen_string_literal: true
require "#{Rails.root}/lib/importers/revision_importer"

#= Fetches and imports new revisions for courses
class CourseRevisionUpdater
  ###############
  # Entry point #
  ###############
  def self.import_new_revisions(courses=nil)
    courses = [courses] if courses.is_a? Course
    courses ||= default_courses_to_update
    courses.each do |course|
      course.update_attribute(:needs_update, false)
      next if course.students.empty?
      new(course).update_revisions_for_relevant_wikis
      ArticlesCourses.update_from_course(course)
    end
  end

  def initialize(course)
    @course = course
  end

  def update_revisions_for_relevant_wikis
    wiki_ids = @course.assignments.pluck(:wiki_id) + [@course.home_wiki.id]
    wiki_ids.uniq.each do |wiki_id|
      RevisionImporter.new(Wiki.find(wiki_id), @course).import_new_revisions_for_course
    end
  end

  ##########
  # Helper #
  ##########
  def self.default_courses_to_update
    Course.current | Course.where(needs_update: true)
  end
end
