# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/revision_data_manager"

#= Fetches and imports new revisions for courses and creates ArticlesCourses records
class CourseRevisionUpdater
  ###############
  # Entry point #
  ###############
  def initialize(course, update_service: nil)
    @course = course
    @update_service = update_service
  end

  def no_point_in_importing_revisions?
    return true if @course.students.empty?
    # If there are no assignments or categories being tracked,
    # there's no point in importing revisions.
    # This avoids treating every update as a 'new users' update
    # for an ArcticleScopedProgram with highly active users
    # but no tracked articles.
    return false unless @course.only_scoped_articles_course?
    @course.assignments.none? && @course.categories.none?
  end

  # Returns a hash with start, end, new_data and revisions (without scores) fetched by wiki.
  # The new_data field is true if new revisions were found.
  # Example:
  # {wiki0 => {:start=>"20160320", :end=>"20160401", :new_data=>true, :revisions=>[...]}}
  # :revisions array is empty if no point in importing revisions.
  # Creates ArticlesCourses records as side effect.
  def fetch_revisions_for_course_wiki(wiki, ts_start, ts_end)
    return empty_response(wiki, ts_start, ts_end) if no_point_in_importing_revisions?
    revision_data = fetch_revisions(wiki, ts_start, ts_end)
    create_articles_courses(revision_data)

    format_revision_response(wiki, ts_start, ts_end, revision_data)
  end

  # Add scores to revisions, except if only_new argument is set to true and there are no new
  # revisions. That means, if the only_new argument is true, revisions scores will only be
  # fetched if there are new revisions for that timeslice.
  # This optimization was added to improve performance.
  def fetch_scores_for_revisions(revision_data, only_new: false)
    wiki = revision_data.keys.first
    values = revision_data.values.first

    # Do not fetch scores if we're only interested in new revisions and there are no new revisions
    return revision_data if only_new && !values[:new_data]

    # Add scores
    values[:revisions] = fetch_scores(wiki, values[:revisions])
    revision_data
  end

  private

  def create_articles_courses(revisions)
    ArticlesCourses.update_from_course_revisions(@course, revisions)
  end

  def format_revision_response(wiki, timeslice_start, timeslice_end, revision_data)
    new_revisions = new_revisions?(revision_data, wiki, timeslice_start)
    results = {}
    revisions = {}
    revisions[:start] = timeslice_start
    revisions[:end] = timeslice_end
    revisions[:new_data] = new_revisions
    revisions[:revisions] = revision_data
    results[wiki] = revisions
    results
  end

  def empty_response(wiki, timeslice_start, timeslice_end)
    format_revision_response(wiki, timeslice_start, timeslice_end, [])
  end

  def fetch_revisions(wiki, timeslice_start, timeslice_end)
    manager = RevisionDataManager.new(wiki, @course, update_service: @update_service)
    manager.fetch_revision_data_for_course(timeslice_start, timeslice_end)
  end

  def fetch_scores(wiki, revisions)
    manager = RevisionDataManager.new(wiki, @course, update_service: @update_service)
    manager.fetch_score_data_for_course(revisions)
  end

  # Determines if there are new revisions, based on the number of revisions and the
  # last revision datetime.
  def new_revisions?(revisions, wiki, timeslice_start)
    live_revisions = revisions.reject(&:system)
    revision_count = live_revisions.count
    timeslice = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                   .for_datetime(timeslice_start)
                                   .first
    if timeslice.nil?
      # This scenario is unexpected, so we log the message to understand why this happens.
      Sentry.capture_message 'No timeslice found for revision date',
                             level: 'error',
                             extra: { course_name: @course.slug,
                                       wiki: wiki.id,
                                       date: timeslice_start }
      return true
    end

    latest_revision = revisions.maximum(:date)
    revision_count != timeslice.revision_count || latest_revision != timeslice.last_mw_rev_datetime
  end
end
