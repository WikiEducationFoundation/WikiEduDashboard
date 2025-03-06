# frozen_string_literal: true

#= Creates/Updates ArticleCourseTimeslice, CourseUserWikiTimeslice
# and CourseWikiTimeslice records.
class TimesliceManager
  def initialize(course)
    @course = course
  end

  def timeslice_duration(wiki)
    begin
      flag = @course.flags[:timeslice_duration]
      flag[wiki.domain.to_sym] || flag[:default]
    rescue StandardError
      TIMESLICE_DURATION
    end.seconds
  end

  # Creates course wiki timeslices records for new course wikis
  # Takes a collection of Wikis
  def create_timeslices_for_new_course_wiki_records(wikis, needs_update: false)
    wikis.each do |wiki|
      create_empty_course_wiki_timeslices(start_dates(wiki), wiki, needs_update:)
    end
  end

  # Creates course wiki timeslices records for missing timeslices due to a change in the start date
  def create_wiki_timeslices_for_new_course_start_date(wiki)
    create_empty_course_wiki_timeslices(start_dates_backward(wiki), wiki,
                                        needs_update: true)
  end

  # Creates course wiki timeslices records for missing timeslices due to a change in the end date
  def create_wiki_timeslices_up_to_new_course_end_date(wiki)
    create_empty_course_wiki_timeslices(start_dates_from_old_end(wiki), wiki,
                                        needs_update: true)
  end

  # Returns a datetime with the date to start getting revisions.
  def get_ingestion_start_time_for_wiki(wiki)
    non_empty_timeslices = @course.course_wiki_timeslices.where(wiki:).reject do |ts|
      ts.last_mw_rev_datetime.nil?
    end

    # Always return timeslice start date, as we need to re-ingest all the data
    # for partially-completed timeslices.
    last_datetime = non_empty_timeslices.max_by(&:last_mw_rev_datetime)&.start

    last_datetime ||= @course.start
    last_datetime
  end

  # Returns a datetime with the date to stop getting revisions.
  def get_latest_start_time_for_wiki(wiki)
    @course.reload
    end_of_course = @course.end
    today = Time.zone.now
    end_of_update_period = [end_of_course, today].min
    CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                       .for_datetime(end_of_update_period)
                       .first
                       .start
  rescue NoMethodError => e
    Sentry.capture_exception e, extra: { course_id: @course.id, wiki_id: wiki.id,
                                         datetime: end_of_update_period }
  end

  # Given an array of revision data per wiki, it updates the last_mw_rev_datetime field
  # for every course wiki timeslice involved.
  # { wiki0=>{:start=>'20181130230005', :end=>'20181140000000', :revisions=>[]},
  #   ...,
  #   wikiN=> {:start=>'20181130210015', :end=>'20181140000000', :revisions=>[revision0,...]} }
  def update_last_mw_rev_datetime(new_fetched_data)
    new_fetched_data.each do |wiki, revision_data|
      # Fetch the timeslices from the db
      timeslices = get_course_wiki_timeslices(wiki, revision_data[:start], revision_data[:end])

      update_timeslices(timeslices, revision_data[:revisions])

      persist_timeslices(timeslices)
    end
  end

  # Marks course wiki timeslices as needs_update for dates with associated revisions
  # Takes a collection of revisions and a wiki
  def update_timeslices_that_need_update_from_revisions(revisions, wiki)
    timeslice_ids = []
    timeslices = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
    timeslices.each do |t|
      revisions_per_timeslice = revisions.select do |r|
        t.start <= r.date && r.date < t.end
      end
      timeslice_ids << t.id unless revisions_per_timeslice.empty?
    end
    CourseWikiTimeslice.where(id: timeslice_ids).update_all(needs_update: true) # rubocop:disable Rails/SkipsModelValidations
  end

  TIMESLICE_DURATION = ENV['TIMESLICE_DURATION'].to_i

  private

  # Creates empty course wiki timeslices
  def create_empty_course_wiki_timeslices(starts, wiki, needs_update: false)
    new_records = starts.map do |start|
      { course_id: @course.id, wiki_id: wiki.id, start:,
        end: start + timeslice_duration(wiki), needs_update: }
    end

    return if new_records.empty?
    # Do this in batches to avoid running the MySQL server out of memory
    new_records.each_slice(5000) do |new_record_slice|
      CourseWikiTimeslice.import new_record_slice, on_duplicate_key_ignore: true
    end
  end

  # Returns start dates from the course start to the course end,
  # ensuring they align with the timeslice duration for the given wiki.
  def start_dates(wiki)
    start_dates = []
    current_start = @course.start
    while current_start <= @course.end
      start_dates << current_start
      current_start += timeslice_duration(wiki)
    end

    start_dates
  end

  # Returns start dates from the old course start up to the new (previous) course start,
  # ensuring they align with the timeslice duration for the given wiki.
  def start_dates_backward(wiki)
    start_dates = []
    old_start = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                   .minimum(:start)
    current_start = old_start - timeslice_duration(wiki)
    while current_start > @course.start - timeslice_duration(wiki)
      start_dates << current_start
      current_start -= timeslice_duration(wiki)
    end

    start_dates
  end

  # Returns start dates from the old course end up to the new (later) course end,
  # ensuring they align with the timeslice duration for the given wiki.
  def start_dates_from_old_end(wiki)
    start_dates = []
    current_start = CourseWikiTimeslice.for_course_and_wiki(@course, wiki).maximum(:end)
    while current_start <= @course.end
      start_dates << current_start
      current_start += timeslice_duration(wiki)
    end

    start_dates
  end

  # Takes an ActiveRecord::Relation of CourseWikiTimeslices and an array of revisions.
  # Updates the last_mw_rev_datetime field based on those revisions.
  def update_timeslices(timeslices, revisions)
    # Iterate over the fetched revisions and update the last_mw_rev_datetime
    revisions.each do |revision|
      # Get the timeslice that we want to update
      timeslice = timeslices.find { |ts| ts.start <= revision.date && ts.end > revision.date }

      if timeslice.nil?
        # This scenario is unexpected, so we log the message to understand why this happens.
        Sentry.capture_message 'No timeslice found for revision date',
                               level: 'warning',
                               extra: { course_name: @course.slug,
                                        wiki: revision.wiki.id,
                                        date: revision.date }
        next
      end
      # Next if the last_mw_rev_datetime field is after the revision date
      if !timeslice.last_mw_rev_datetime.nil? && timeslice.last_mw_rev_datetime >= revision.date
        next
      end
      # Update last_mw_rev_datetime
      timeslice.last_mw_rev_datetime = revision.date
    end
  end

  def persist_timeslices(timeslices)
    # We need to convert the ActiveRecord::Relation to an array of attribute hashes to use import
    timeslice_attributes = timeslices.map(&:attributes)

    # Perform the import at once updating only last_mw_rev_datetime
    CourseWikiTimeslice.import timeslice_attributes,
                               on_duplicate_key_update: ['last_mw_rev_datetime']
  end

  def get_course_wiki_timeslices(wiki, period_start, period_end)
    CourseWikiTimeslice.for_course_and_wiki(@course, wiki).for_revisions_between(period_start,
                                                                                 period_end)
  end
end
