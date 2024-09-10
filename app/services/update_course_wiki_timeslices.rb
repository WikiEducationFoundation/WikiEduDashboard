# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"
require_dependency "#{Rails.root}/lib/data_cycle/update_logger"
require_dependency "#{Rails.root}/lib/errors/update_service_error_helper"
require_dependency "#{Rails.root}/lib/timeslice_manager"

#= Pulls in new revisions for a single course and updates the corresponding timeslices records.
# It updates all the tracked wikis for the course, from the latest start time for every wiki
# up to the end of update (today or end date course).
class UpdateCourseWikiTimeslices
  include UpdateServiceErrorHelper

  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(@course)
    @course_wiki_updater = CourseWikiUpdater.new(@course)
  end

  def run(all_time:)
    all_time ? clean_timeslices : @course_wiki_updater.run
    fetch_data_and_process_timeslices_for_every_wiki(all_time)
    error_count
  end

  private

  # Delete and recreate timeslices
  def clean_timeslices
    wiki_ids = @course.wikis.pluck(:wiki_id)
    @timeslice_manager.delete_timeslices_for_deleted_course_wikis(wiki_ids)
    # Destroy articles courses records to re-create article courses timeslices
    @course.articles_courses.destroy_all
    @timeslice_manager.create_timeslices_for_new_course_wiki_records(@course.wikis)
  end

  def fetch_data_and_process_timeslices_for_every_wiki(all_time)
    @course.wikis.each do |wiki|
      # Get start time from first timeslice to update
      first_start = if all_time
                      @course.start.strftime('%Y%m%d%H%M%S')
                    else
                      @timeslice_manager.get_ingestion_start_time_for_wiki(wiki)
                    end
      # Get start time from latest timeslice to update
      latest_start = get_latest_start_time_for_wiki(wiki)

      fetch_data_and_process_timeslices(wiki, first_start, latest_start)
    end
    log_update_progress :course_timeslices_updated
  end

  def get_latest_start_time_for_wiki(wiki)
    end_of_course = @course.end.end_of_day
    today = Time.zone.now
    end_of_update_period = [end_of_course, today].min
    CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                       .for_datetime(end_of_update_period)
                       .first
                       .start
  end

  def fetch_data_and_process_timeslices(wiki, first_start, latest_start)
    current_start = first_start.to_datetime
    while current_start <= latest_start
      fetch_data(wiki, current_start, current_start + TimesliceManager::TIMESLICE_DURATION)
      process_timeslices(wiki)
      current_start += TimesliceManager::TIMESLICE_DURATION
    end
  end

  def fetch_data(wiki, timeslice_start, timeslice_end)
    log_update_progress :start
    # Fetches revision for wiki
    @revisions = CourseRevisionUpdater
                 .fetch_revisions_and_scores_for_wiki(@course,
                                                      wiki,
                                                      timeslice_start.strftime('%Y%m%d%H%M%S'),
                                                      timeslice_end.strftime('%Y%m%d%H%M%S'),
                                                      update_service: self)
    # TODO: replace the logic on ArticlesCourses.update_from_course to remove all
    # the ArticlesCourses that do not correspond to course revisions.
    # That may happen if the course dates changed, so some revisions are no
    # longer part of the course.
    # Also remove records for articles that aren't on a tracked wiki.
    log_update_progress :revision_scores_fetched
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

  def log_update_progress(step)
    return unless debug?
    @sentry_logs ||= {}
    @sentry_logs[step] = Time.zone.now
    Sentry.capture_message "#{@course.title} update: #{step}",
                           level: 'warning',
                           extra: { logs: @sentry_logs }
  end

  def log_error(error)
    Sentry.capture_message "#{@course.title} update timeslices error: #{error}",
                           level: 'error'
  end

  def debug?
    @course.flags[:debug_updates]
  end
end
