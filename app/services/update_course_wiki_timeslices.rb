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
    @splitter = SplitTimeslice.new(@course, update_service:)
    @debugger = debugger
    @update_service = update_service
    @processed_timeslices_count = 0
    @reprocessed_timeslices = Hash.new { |h, k| h[k] = [] }
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
        processed = @splitter.handle(wiki, t.start, t.end, only_new: true)
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
        reprocessed_dates = @splitter.handle(wiki, t.start, t.end, only_new: false)
        @reprocessed_timeslices[wiki.id] += reprocessed_dates
      rescue StandardError => e
        log_error(e)
        raise ActiveRecord::Rollback
      end
    end
  end

  def timeslice_reprocessed?(wiki_id, start_date)
    @reprocessed_timeslices[wiki_id].include?(start_date)
  end

  def log_error(error)
    Sentry.capture_message "#{@course.slug} update timeslices error: #{error}",
                           level: 'error'
  end
end
