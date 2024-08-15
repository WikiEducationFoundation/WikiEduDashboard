# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/importers/revision_importer"
require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/revision_data_manager"

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

  # Returns a hash with start, end and revisions fetched by wiki or an empty
  # hash if no point in importing revisions.
  # :start is the date from which revisions were retrieved.
  # :end is the date of the last revision retrieved.
  # We only have guarantees that we have the revisions up to that date.
  # Example:
  # {wiki0 => {:start=>"20160320034055", :end=>"20160401194010", :revisions=>[...]},
  # ...,
  # wikiN => {:start=>"20160328000500", :end=>"20160401220541", :revisions=>[...]}}
  def self.fetch_revisions_and_scores(course, update_service: nil)
    return {} if no_point_in_importing_revisions?(course)
    revision_data = new(course, update_service:)
                    .fetch_revisions_and_scores_for_relevant_wikis
    # Get an array with all revisions
    revisions = revision_data.values.flat_map { |data| data[:revisions] }.flatten
    ArticlesCourses.update_from_course_revisions(course, revisions)
    revision_data
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
    results = {}
    @course.wikis.each do |wiki|
      start = @timeslice_manager.get_last_mw_rev_datetime_for_wiki(wiki)
      # TODO: We should fetch data even after the course end to calculate retention.
      # However, right now this causes problems due to lack of timeslices for those days.
      end_of_course = @course.end.end_of_day.strftime('%Y%m%d%H%M%S')
      today = Time.zone.now.strftime('%Y%m%d%H%M%S')
      end_of_update_period = [end_of_course, today].min

      results[wiki] = prepare_revisions_per_wiki(wiki, start, end_of_update_period)
    end
    results
  end

  def prepare_revisions_per_wiki(wiki, start_period, end_period)
    result = {}
    revisions = RevisionDataManager
                .new(wiki, @course, update_service: @update_service)
                .fetch_revision_data_for_course(start_period, end_period)

    result[:start] = start_period
    # We only have guarantees that we have revisions up to the max revision date.
    result[:end] =
      revisions.empty? ? start_period : revisions.map(&:date).max.strftime('%Y%m%d%H%M%S')
    result[:revisions] = revisions
    result
  end
end
