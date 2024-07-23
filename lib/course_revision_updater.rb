# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/importers/revision_importer"
require_dependency "#{Rails.root}/lib/timeslice_manager"

#= Fetches and imports new revisions for courses and creates ArticlesCourses records
class CourseRevisionUpdater
  ###############
  # Entry point #
  ###############
  def self.import_revisions(course, all_time:, update_service: nil)
    return if no_point_in_importing_revisions?(course)
    new(course, update_service:).update_revisions_for_relevant_wikis(all_time)
    ArticlesCourses.update_from_course(course)
  end

  # Returns a hash with revisions by wiki or an empty hash if no point in importing revisions
  def self.fetch_revisions_and_scores(course, update_service: nil)
    return {} if no_point_in_importing_revisions?(course)
    revisions = new(course, update_service:)
                .fetch_revisions_and_scores_for_relevant_wikis
    ArticlesCourses.update_from_course_revisions(course, revisions.values.flatten)
    revisions
  end

  def self.no_point_in_importing_revisions?(course)
    return true if course.students.empty?
    # If there are no assignments or categories being tracked,
    # there's no point in importing revisions.
    # This avoids treating every update as a 'new users' update
    # for an ArcticleScopedProgram with highly active users
    # but no tracked articles.
    return false unless course.type == 'ArticleScopedProgram'
    course.assignments.none? && course.categories.none?
  end

  def initialize(course, update_service: nil)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
    @update_service = update_service
  end

  def update_revisions_for_relevant_wikis(all_time)
    @course.wikis.each do |wiki|
      RevisionImporter.new(wiki, @course, update_service: @update_service)
                      .import_revisions_for_course(all_time:)
    end
  end

  def fetch_revisions_and_scores_for_relevant_wikis
    # Fetchs revision for each wiki
    revisions = {}
    @course.wikis.each do |wiki|
      start = @timeslice_manager.get_last_mw_rev_datetime_for_wiki(wiki)
      # TODO: We should fetch data even after the course end to calculate retention.
      # However, right now this causes problems due to lack of timeslices for those days.
      end_of_update_period = (@course.end + 1.day).strftime('%Y%m%d')
      revisions[wiki] = RevisionDataManager
                        .new(wiki, @course, update_service: @update_service)
                        .fetch_revision_data_for_course(start, end_of_update_period)
    end
    revisions
  end
end
