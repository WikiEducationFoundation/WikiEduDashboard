# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"
require_dependency "#{Rails.root}/lib/data_cycle/update_logger"
require_dependency "#{Rails.root}/lib/errors/update_service_error_helper"
require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/data_cycle/update_debugger"

#= Pulls in new revisions for a single course and updates the corresponding timeslices records.
# It updates all the tracked wikis for the course, from the latest start time for every wiki
# up to the end of update (today or end date course).
class UpdateCourseWikiTimeslices
  include UpdateServiceErrorHelper

  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(@course)
    @debugger = UpdateDebugger.new(@course)
    @wikidata_stats_updater = UpdateWikidataStatsTimeslice.new(@course) if wikidata
  end

  def run(all_time:)
    pre_update(all_time)
    fetch_data_and_process_timeslices_for_every_wiki(all_time)
    error_count
  end

  private

  def pre_update(from_scratch)
    @debugger.log_update_progress :pre_update_start
    prepare_timeslices = PrepareTimeslices.new(@course)
    from_scratch ? prepare_timeslices.recreate_timeslices : prepare_timeslices.adjust_timeslices
    @debugger.log_update_progress :pre_update_finish
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
      fetch_data_and_reprocess_timeslices(wiki)

      fetch_data_and_process_timeslices(wiki, first_start, latest_start)
    end
    @debugger.log_update_progress :course_timeslices_updated
  end

  def fetch_data_and_process_timeslices(wiki, first_start, latest_start)
    @debugger.log_update_progress :fetch_and_process_timeslices_start
    current_start = first_start
    while current_start <= latest_start
      start_date = [current_start, @course.start].max
      end_date = [current_start + TimesliceManager::TIMESLICE_DURATION - 1.second, @course.end].min
      fetch_data(wiki, start_date, end_date)
      process_timeslices(wiki)
      current_start += TimesliceManager::TIMESLICE_DURATION
    end
    @debugger.log_update_progress :fetch_and_process_timeslices_finish
  end

  def fetch_data_and_reprocess_timeslices(wiki)
    @debugger.log_update_progress :fetch_and_reprocess_timeslices_start
    to_reprocess = CourseWikiTimeslice.for_course_and_wiki(@course, wiki).needs_update
    to_reprocess.each do |t|
      start_date = [t.start, @course.start].max
      end_date = [t.end - 1.second, @course.end].min
      fetch_data(wiki, start_date, end_date)
      process_timeslices(wiki)
    end
    @debugger.log_update_progress :fetch_and_reprocess_timeslices_finish
  end

  def fetch_data(wiki, timeslice_start, timeslice_end)
    # Fetches revision for wiki
    @revisions = CourseRevisionUpdater
                 .fetch_revisions_and_scores_for_wiki(@course,
                                                      wiki,
                                                      timeslice_start.strftime('%Y%m%d%H%M%S'),
                                                      timeslice_end.strftime('%Y%m%d%H%M%S'),
                                                      update_service: self)

    # Only for wikidata project, fetch wikidata stats
    if wiki.project == 'wikidata' && @revisions.present?
      wikidata_revisions = @revisions[wiki][:revisions]
      @revisions[wiki][:revisions] =
        @wikidata_stats_updater.update_revisions_with_stats(wikidata_revisions)
    end
    # TODO: replace the logic on ArticlesCourses.update_from_course to remove all
    # the ArticlesCourses that do not correspond to course revisions.
    # That may happen if the course dates changed, so some revisions are no
    # longer part of the course.
    # Also remove records for articles that aren't on a tracked wiki.
  end

  def process_timeslices(wiki)
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
      article_course = ArticlesCourses.find_by(course: @course, article_id:)
      next unless article_course

      # Update cache for ArticleCorseTimeslice
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
    Sentry.capture_message "#{@course.title} update timeslices error: #{error}",
                           level: 'error'
  end
end
