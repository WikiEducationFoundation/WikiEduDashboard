# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/data_cycle/update_debugger"

#= Pulls in new revisions for a single course and updates the corresponding timeslices records.
# It updates all the tracked wikis for the course, from the latest start time for every wiki
# up to the end of update (today or end date course).
class UpdateCourseWikiTimeslices
  def initialize(course, debugger, update_service: nil)
    @course = course
    @timeslice_manager = TimesliceManager.new(@course)
    @debugger = debugger
    @update_service = update_service
    @wikidata_stats_updater = UpdateWikidataStatsTimeslice.new(@course) if wikidata
    @processed_timeslices = 0
    @reprocessed_timeslices = 0
  end

  def run(all_time:)
    pre_update(all_time)
    fetch_data_and_process_timeslices_for_every_wiki(all_time)
    [@processed_timeslices, @reprocessed_timeslices]
  end

  private

  def pre_update(from_scratch)
    prepare_timeslices = PrepareTimeslices.new(@course, @debugger, update_service: @update_service)
    from_scratch ? prepare_timeslices.recreate_timeslices : prepare_timeslices.adjust_timeslices
  end

  def fetch_data_and_process_timeslices_for_every_wiki(all_time)
    @course.wikis.each do |wiki|
      # Sometimes we need to reprocess timeslices due to changes such as
      # users removed from a course.
      fetch_data_and_reprocess_timeslices(wiki)

      # Get start time from first timeslice to update
      first_start = if all_time
                      CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                         .for_datetime(@course.start).first.start
                    else
                      @timeslice_manager.get_ingestion_start_time_for_wiki(wiki)
                    end
      # Get start time from latest timeslice to update
      latest_start = @timeslice_manager.get_latest_start_time_for_wiki(wiki)

      fetch_data_and_process_timeslices(wiki, first_start, latest_start)
      @debugger.log_update_progress "timeslices_processed_#{wiki.id}".to_sym
    end
  end

  def fetch_data_and_process_timeslices(wiki, first_start, latest_start)
    current_start = first_start
    while current_start <= latest_start
      start_date = [current_start, @course.start].max
      end_date = [current_start + @timeslice_manager.timeslice_duration(wiki) - 1.second,
                  @course.end].min

      log_processing(wiki, start_date, end_date)

      fetch_data(wiki, start_date, end_date)
      process_timeslices(wiki)
      current_start += @timeslice_manager.timeslice_duration(wiki)
      @processed_timeslices += 1
    end
  end

  def fetch_data_and_reprocess_timeslices(wiki)
    to_reprocess = CourseWikiTimeslice.for_course_and_wiki(@course, wiki).needs_update
    to_reprocess.each do |t|
      start_date = [t.start, @course.start].max
      end_date = [t.end - 1.second, @course.end].min

      log_reprocessing(wiki, start_date, end_date)

      fetch_data(wiki, start_date, end_date)
      process_timeslices(wiki)
      @reprocessed_timeslices += 1
    end
  end

  def fetch_data(wiki, timeslice_start, timeslice_end)
    # Fetches revision for wiki
    @revisions = CourseRevisionUpdater
                 .fetch_revisions_and_scores_for_wiki(@course,
                                                      wiki,
                                                      timeslice_start.strftime('%Y%m%d%H%M%S'),
                                                      timeslice_end.strftime('%Y%m%d%H%M%S'),
                                                      update_service: @update_service)

    # Only for wikidata project, fetch wikidata stats
    return unless wiki.project == 'wikidata' && @revisions.present?
    wikidata_revisions = @revisions[wiki][:revisions].reject(&:deleted)
    @revisions[wiki][:revisions] =
      @wikidata_stats_updater.update_revisions_with_stats(wikidata_revisions)
  end

  def process_timeslices(wiki)
    @course.reload
    # Update timeslices
    ActiveRecord::Base.transaction do
      update_timeslices(wiki)
      @timeslice_manager.update_last_mw_rev_datetime(@revisions)

    rescue StandardError => e
      log_error(e)
      raise ActiveRecord::Rollback
    end
  end

  def update_timeslices(wiki)
    return if @revisions.length.zero?
    update_course_user_wiki_timeslices_for_wiki(wiki, @revisions[wiki])
    update_article_course_timeslices_for_wiki(@revisions[wiki])
    CourseWikiTimeslice.update_course_wiki_timeslices(@course, wiki, @revisions[wiki])
  end

  def update_article_course_timeslices_for_wiki(revisions)
    start_period = revisions[:start]
    end_period = revisions[:end]
    revs = revisions[:revisions]
    revs.group_by(&:article_id).each do |article_id, article_revisions|
      # We don't create articles courses for every article
      # article_course = ArticlesCourses.find_by(course: @course, article_id:)
      # next unless article_course

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

  def log_error(error)
    Sentry.capture_message "#{@course.slug} update timeslices error: #{error}",
                           level: 'error'
  end

  def log_processing(wiki, start_date, end_date)
    Rails.logger.info "UpdateCourseWikiTimeslices: Course: #{@course.slug} Wiki: #{wiki.id}.\
    Processing timeslice [#{start_date}, #{end_date}]"
  end

  def log_reprocessing(wiki, start_date, end_date)
    Rails.logger.info "UpdateCourseWikiTimeslices: Course: #{@course.slug} Wiki: #{wiki.id}.\
    Reprocessing timeslice [#{start_date}, #{end_date}]"
  end
end
