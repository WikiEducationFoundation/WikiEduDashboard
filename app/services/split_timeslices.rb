# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/timeslice_cleaner"
require_dependency "#{Rails.root}/lib/data_cycle/update_debugger"
require_dependency "#{Rails.root}/lib/revision_scanner"

#= Implements the adaptive timeslice splitting strategy.
# The algorithm starts with a default timeslice, fetches revisions for that period
# and, if the timeslice exceeds the threshold, recursively splits it until all
# timeslices are within limits.
class SplitTimeslices
  def initialize(course, update_service: nil)
    @course = course
    @timeslice_manager = TimesliceManager.new(@course)
    @timeslice_cleaner = TimesliceCleaner.new(@course)
    @revision_updater = CourseRevisionUpdater.new(@course, update_service:)
    @wikidata_stats_updater = UpdateWikidataStatsTimeslice.new(@course) if wikidata
  end

  # Max desirable number of revisions per timeslice
  REVISION_THRESHOLD = 10000

  # Given a wiki and limites of the timeslice, it fetches data for it
  # (maybe splitting the timeslice if too many revisions) and
  # returns an array with start dates for timeslices that were processed.
  # start_date and end_date are the limits of the timeslice records
  def handle(wiki, start_date, end_date, only_new: true)
    fetch_only_revisions(wiki, start_date, end_date)
    if too_many_revisions?(wiki) && splittable?(start_date, end_date)
      split_timeslice(wiki, start_date, end_date)
    else
      log_processing(wiki, start_date, end_date, only_new)
      # Ensure course wiki timeslice exists for course, wiki and dates
      @timeslice_manager.maybe_create_course_wiki_timeslice(wiki.id, start_date, end_date)
      fetch_revisions(wiki, start_date, end_date, only_new:)
      maybe_fetch_wikidata_stats(wiki)
      process_timeslices(wiki) if !only_new | new_data?(wiki)
      [start_date]
    end
  end

  private

  def too_many_revisions?(wiki)
    @revisions[wiki][:revisions].count(&:scoped) > REVISION_THRESHOLD
  end

  # A timeslice is not split if its duration is an odd number of seconds.
  # This is because the revisions API expects start and end times in
  # YYYY-MM-DD HH:MM:SS format, which does not allow fractions of a second.
  def splittable?(start_date, end_date)
    # Ensure start and end are times here, since otherwise the substraction
    # works differently.
    seconds = (end_date.to_time - start_date.to_time).to_i
    seconds.even?
  end

  def split_timeslice(wiki, start_date, end_date)
    # Delete course wiki timeslice that exceeds REVISION_THRESHOLD. Note this timeslice
    # may not exist. We also need to delete ACT and CUWT associated to that wiki and dates.
    @timeslice_cleaner.delete_timeslices_for_period([wiki], start_date, end_date)

    middle_point = start_date + ((end_date - start_date) / 2)
    handle(wiki, start_date, middle_point) + handle(wiki, middle_point, end_date)
  end

  def fetch_revisions(wiki, timeslice_start, timeslice_end, only_new:)
    # Fetches revision for wiki
    @revisions = @revision_updater.fetch_full_data_for_course_wiki(
      wiki,
      real_start(timeslice_start).strftime('%Y%m%d%H%M%S'),
      real_end(timeslice_end).strftime('%Y%m%d%H%M%S'),
      only_new:
    )
  end

  def fetch_only_revisions(wiki, timeslice_start, timeslice_end)
    # Fetches only revision for wiki
    @revisions = @revision_updater.fetch_revisions_for_course_wiki(
      wiki,
      real_start(timeslice_start).strftime('%Y%m%d%H%M%S'),
      real_end(timeslice_end).strftime('%Y%m%d%H%M%S')
    )
  end

  def real_start(timeslice_start)
    [timeslice_start, @course.start].max
  end

  def real_end(timeslice_end)
    [timeslice_end - 1.second, @course.end].min
  end

  def maybe_fetch_wikidata_stats(wiki)
    fetch_wikidata_stats(wiki) if wiki.project == 'wikidata' && new_data?(wiki)
  end

  def new_data?(wiki)
    @revisions[wiki][:new_data]
  end

  # Only for wikidata project, fetch wikidata stats
  def fetch_wikidata_stats(wiki)
    wikidata_revisions = @revisions[wiki][:revisions].reject(&:deleted)
    @revisions[wiki][:revisions] =
      @wikidata_stats_updater.update_revisions_with_stats(wikidata_revisions)
  end

  def process_timeslices(wiki)
    @course.reload
    update_timeslices(wiki)
    @timeslice_manager.update_last_mw_rev_datetime(@revisions)
  end

  def update_timeslices(wiki)
    update_course_user_wiki_timeslices_for_wiki(wiki, @revisions[wiki])
    update_article_course_timeslices_for_wiki(@revisions[wiki])

    revs_to_scan = @revisions[wiki][:revisions]
    RevisionScanner.schedule_revision_checks(wiki:, revisions: revs_to_scan, course: @course)

    CourseWikiTimeslice.update_course_wiki_timeslices(@course, wiki, @revisions[wiki])
  end

  def update_article_course_timeslices_for_wiki(revisions)
    start_period = revisions[:start]
    end_period = revisions[:end]
    revs = revisions[:revisions]
    revs.group_by(&:article_id).each do |article_id, article_revisions|
      # We create articles courses timeslices for every article
      # Update cache for ArticleCourseTimeslice
      article_revisions_data = { start: start_period, end: end_period,
                                 revisions: article_revisions }
      ArticleCourseTimeslice.update_article_course_timeslices(@course, article_id,
                                                              article_revisions_data)
    end
  end

  def update_course_user_wiki_timeslices_for_wiki(wiki, revisions)
    start_period = revisions[:start]
    end_period = revisions[:end]
    revs = revisions[:revisions]
    revs.group_by(&:user_id).each do |user_id, user_revisions|
      # Update cache for CourseUserWikiTimeslice
      course_user_wiki_data = { start: start_period, end: end_period,
                                revisions: user_revisions }
      CourseUserWikiTimeslice.update_course_user_wiki_timeslices(@course, user_id, wiki,
                                                                 course_user_wiki_data)
    end
  end

  def wikidata
    @course.wikis.find { |wiki| wiki.project == 'wikidata' }
  end

  def log_processing(wiki, start_date, end_date, reprocessing)
    if reprocessing
      Rails.logger.info "UpdateCourseWikiTimeslices: Course: #{@course.slug} Wiki: #{wiki.id}.\
      Reprocessing timeslice [#{start_date}, #{end_date}]"
    else
      Rails.logger.info "UpdateCourseWikiTimeslices: Course: #{@course.slug} Wiki: #{wiki.id}.\
      Proprocessing timeslice [#{start_date}, #{end_date}]"
    end
  end
end
