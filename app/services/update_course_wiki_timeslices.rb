# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/data_cycle/update_debugger"
require_dependency "#{Rails.root}/lib/revision_scanner"

#= Pulls in new revisions for a single course and updates the corresponding timeslices records.
# It updates all the tracked wikis for the course, from the latest start time for every wiki
# up to the end of update (today or end date course).
# Timeslices are updated using the adaptive timeslice splitting strategy.
# The algorithm starts with a default timeslice, fetches revisions for that period
# and, if the timeslice exceeds the threshold, recursively splits it until all
# timeslices are within limits.
class UpdateCourseWikiTimeslices
  def initialize(course, debugger, update_service: nil)
    @course = course
    @timeslice_manager = TimesliceManager.new(@course)
    @splitter = SplitTimeslice.new(@course)
    @debugger = debugger
    @update_service = update_service
    @processed_timeslices_count = 0
    @reprocessed_timeslices = Hash.new { |h, k| h[k] = [] }
    @revision_updater = CourseRevisionUpdater.new(@course, update_service:)
    @wikidata_stats_updater = UpdateWikidataStatsTimeslice.new(@course) if wikidata
  end

  def run(all_time:)
    pre_update(all_time)
    @course.update(needs_update: false)
    fetch_data_and_process_timeslices_for_every_wiki(all_time)
    [@processed_timeslices_count, @reprocessed_timeslices.values.flatten.count]
  end

  private

  def pre_update(from_scratch)
    prepare_timeslices = PrepareTimeslices.new(@course, @debugger, update_service: @update_service)
    from_scratch ? prepare_timeslices.recreate_timeslices : prepare_timeslices.adjust_timeslices
  end

  def fetch_data_and_process_timeslices_for_every_wiki(all_time)
    @course.wikis.each do |wiki|
      # Get start time from first timeslice to update
      first_start = if all_time
                      CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                         .for_datetime(@course.start).first.start
                    else
                      @timeslice_manager.get_ingestion_start_time_for_wiki(wiki)
                    end
      # Get start time from latest timeslice to update
      latest_start = @timeslice_manager.get_latest_start_time_for_wiki(wiki)

      # Sometimes we need to reprocess timeslices due to changes such as
      # users removed from a course.
      fetch_data_and_reprocess_timeslices(wiki, first_start)

      fetch_data_and_process_timeslices(wiki, first_start, latest_start)
      @debugger.log_update_progress "timeslices_processed_#{wiki.id}".to_sym
    end
  end

  def fetch_data_and_process_timeslices(wiki, first_start, latest_start)
    to_process = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                    .where('start >= ?', first_start)
                                    .where('start <= ?', latest_start)
    to_process.each do |t|
      # If the timeslice was reprocessed in this update, then skip it
      next if timeslice_reprocessed?(wiki.id, t.start)

      ActiveRecord::Base.transaction do
        processed = handle_timeslice(wiki, t.start, t.end, only_new: true)
        @processed_timeslices_count += processed.count
      rescue StandardError => e
        log_error(e)
        raise ActiveRecord::Rollback
      end
    end
  end

  def fetch_data_and_reprocess_timeslices(wiki, ingestion_start)
    to_reprocess = CourseWikiTimeslice.for_course_and_wiki(@course, wiki).needs_update
    to_reprocess.each do |t|
      # Never reprocess a future timeslice
      if t.start > ingestion_start
        t.update(needs_update: false)
        next
      end

      ActiveRecord::Base.transaction do
        reprocessed_dates = handle_timeslice(wiki, t.start, t.end, only_new: false)
        @reprocessed_timeslices[wiki.id] += reprocessed_dates
      rescue StandardError => e
        log_error(e)
        raise ActiveRecord::Rollback
      end
    end
  end

  # Given a wiki and limits of the timeslice, it fetches data for it
  # (maybe splitting the timeslice if too many revisions) and
  # returns an array with start dates for timeslices that were processed.
  # start_date and end_date are the limits of the timeslice records
  def handle_timeslice(wiki, start_date, end_date, only_new:)
    fetch_only_revisions(wiki, start_date, end_date)
    split, dates = @splitter.maybe_split(wiki, start_date, end_date, @revisions)
    if split
      new_start = dates[0]
      midpoint = dates[1]
      new_end = dates[2]
      handle_timeslice(wiki, new_start, midpoint,
                       only_new:) + handle_timeslice(wiki, midpoint, new_end, only_new:)
    else
      log_processing(wiki, start_date, end_date, only_new)
      add_scores(only_new:)
      maybe_fetch_wikidata_stats(wiki)
      process_timeslices(wiki) if !only_new | new_data?(wiki)
      [start_date]
    end
  end

  def timeslice_reprocessed?(wiki_id, start_date)
    @reprocessed_timeslices[wiki_id].include?(start_date)
  end

  def add_scores(only_new:)
    @revision_updater.fetch_scores_for_revisions(@revisions, only_new:)
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

  def log_processing(wiki, start_date, end_date, processing)
    if processing
      Rails.logger.info "UpdateCourseWikiTimeslices: Course: #{@course.slug} Wiki: #{wiki.id}.\
      Processing timeslice [#{start_date}, #{end_date}]"
    else
      Rails.logger.info "UpdateCourseWikiTimeslices: Course: #{@course.slug} Wiki: #{wiki.id}.\
      Reprocessing timeslice [#{start_date}, #{end_date}]"
    end
  end

  def log_error(error)
    Sentry.capture_message "#{@course.slug} update timeslices error: #{error}",
                           level: 'error'
  end
end
