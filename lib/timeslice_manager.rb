# frozen_string_literal: true

#= Creates/Removes/Updates ArticleCourseTimeslice, CourseUserWikiTimeslice
# and CourseWikiTimeslice records.
class TimesliceManager # rubocop:disable Metrics/ClassLength
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

  # Deletes course user wiki timeslices records for removed course users
  # Takes a collection of user ids
  def delete_course_user_timeslices_for_deleted_course_users(user_ids)
    return if user_ids.empty?

    timeslice_ids = CourseUserWikiTimeslice.where(course: @course, user_id: user_ids).pluck(:id)

    return if timeslice_ids.empty?

    delete_course_user_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes course wiki timeslices records for removed course wikis
  # Deletes course user timeslices records for removed course wiki
  # Deletes article course timeslices records for removed course wiki
  # Takes a collection of wiki ids
  def delete_timeslices_for_deleted_course_wikis(wiki_ids)
    return if wiki_ids.empty?
    delete_existing_course_wiki_timeslices(wiki_ids)
    delete_existing_course_user_wiki_timeslices(wiki_ids)
    delete_existing_article_course_timeslices(wiki_ids)
  end

  # Deletes course wiki timeslices records with a date prior to the current start date
  def delete_course_wiki_timeslices_prior_to_start_date
    # Delete course wiki timeslices
    timeslice_ids = CourseWikiTimeslice.where(course: @course)
                                       .where('end <= ?', @course.start)
                                       .pluck(:id)

    delete_course_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes course wiki timeslices records with a start date later than the current end date
  def delete_course_wiki_timeslices_after_end_date
    wikis = @course.wikis
    delete_course_wiki_timeslices_after_date(wikis, @course.end)
  end

  # Deletes course wiki timeslices records with a start date later than the specific given date
  def delete_course_wiki_timeslices_after_date(wikis, date)
    # Delete course wiki timeslices
    timeslice_ids = CourseWikiTimeslice.where(course: @course)
                                       .where(wiki: wikis)
                                       .where('start > ?', date)
                                       .pluck(:id)

    delete_course_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes course user wiki timeslices records with a date prior to the current start date
  def delete_course_user_wiki_timeslices_prior_to_start_date
    # Delete course user wiki timeslices
    timeslice_ids = CourseUserWikiTimeslice.where(course: @course)
                                           .where('end <= ?', @course.start)
                                           .pluck(:id)

    delete_course_user_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes course user wiki timeslices records with a start date later than the current end date
  def delete_course_user_wiki_timeslices_after_end_date
    # Delete course user wiki timeslices
    timeslice_ids = CourseUserWikiTimeslice.where(course: @course)
                                           .where('start > ?', @course.end)
                                           .pluck(:id)

    delete_course_user_wiki_timeslice_ids(timeslice_ids)
  end

  # Creates course wiki timeslices records for new course wikis
  # Creates course user timeslices records for new course wiki
  # Takes a collection of Wikis
  def create_timeslices_for_new_course_wiki_records(wikis)
    wikis.each do |wiki|
      create_empty_course_wiki_timeslices(start_dates(wiki), wiki)
    end
  end

  # Creates course wiki timeslices records for missing timeslices due to a change in the start date
  # Creates course user wiki timeslices records for missing timeslices
  def create_wiki_timeslices_for_new_course_start_date(wiki)
    create_empty_course_wiki_timeslices(start_dates_backward(wiki), wiki,
                                        needs_update: true)
  end

  # Creates course wiki timeslices records for missing timeslices due to a change in the end date
  # Creates course user wiki timeslices records for missing timeslices
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
    Sentry.capture_exception e, extra: { course_id: @course.id,
                                         wiki_id: wiki.id,
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

  # Resets course wiki timeslices. This involves:
  # - Marking timeslices as needs_update for dates with associated article course timeslices
  # - Deleting given article course timeslices if no soft
  # - Deleting course user wiki timeslices for those dates and wikis
  # Takes a collection of article course timeslices
  def reset_timeslices_that_need_update_from_article_timeslices(timeslices,
                                                                wiki: nil,
                                                                soft: false)
    return if timeslices.empty?

    wikis_and_starts = get_wiki_and_start_dates_to_reprocess(timeslices, wiki)

    # Prepare the list of tuples for SQL
    tuples_list = wikis_and_starts.map do |wiki_id, start_date|
      "(#{wiki_id}, '#{start_date}')"
    end.join(', ')

    # Perform the query using raw SQL for specific (wiki_id, start_date) pairs
    course_wiki_timeslices = CourseWikiTimeslice.where(course: @course)
                                                .where("(wiki_id, start) IN (#{tuples_list})")

    # Update all CourseWikiTimeslice records with matching course, wiki and start dates
    course_wiki_timeslices.update_all(needs_update: true) # rubocop:disable Rails/SkipsModelValidations

    delete_article_course_timeslice_ids(timeslices.pluck(:id)) unless soft

    # Perform the query using raw SQL for specific (wiki_id, start_date) pairs
    cuw_imeslices = CourseUserWikiTimeslice.where(course: @course)
                                           .where("(wiki_id, start) IN (#{tuples_list})")

    delete_course_user_wiki_timeslice_ids(cuw_imeslices.pluck(:id))
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

  # Deletes existing course wiki timeslices for a collection of wiki ids
  def delete_existing_course_wiki_timeslices(wiki_ids)
    # Collect the ids of timeslices to be deleted
    timeslice_ids = CourseWikiTimeslice.where(course_id: @course.id, wiki_id: wiki_ids).pluck(:id)

    return if timeslice_ids.empty?

    delete_course_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes existing course user wiki timeslices for a collection of wiki ids
  def delete_existing_course_user_wiki_timeslices(wiki_ids)
    # Collect the ids of timeslices to be deleted
    timeslice_ids = CourseUserWikiTimeslice.where(course_id: @course.id,
                                                  wiki_id: wiki_ids).pluck(:id)

    return if timeslice_ids.empty?

    delete_course_user_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes existing article course timeslices for a collection of wiki ids
  def delete_existing_article_course_timeslices(wiki_ids)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles_from_timeslices(wiki_ids).pluck(:id)

    # Collect the ids of timeslices to be deleted
    timeslice_ids = ArticleCourseTimeslice.where(course_id: @course.id,
                                                 article_id: article_ids).pluck(:id)

    return if timeslice_ids.empty?

    delete_article_course_timeslice_ids(timeslice_ids)
  end

  # Returns (wiki, start) tuples for timeslices to reprocess
  def get_wiki_and_start_dates_to_reprocess(article_course_timeslices, wiki = nil)
    # Extract article IDs and start dates as unique pairs
    articles_and_starts = article_course_timeslices.map do |timeslice|
      [timeslice.article_id, timeslice.start.strftime('%Y-%m-%d %H:%M:%S')]
    end.uniq

    return articles_and_starts.map { |_, start| [wiki, start] }.uniq if wiki

    # Fetch articles and map article IDs to their corresponding wiki IDs
    id_to_wiki_map = Article.where(id: articles_and_starts.map(&:first))
                            .index_by(&:id)
                            .transform_values(&:wiki_id)

    # Return unique combinations of wiki IDs and start dates
    articles_and_starts.map { |article_id, start| [id_to_wiki_map[article_id], start] }.uniq
  end

  # Returns start dates from the course start up to course end, for timeslices with
  # TIMESLICE_DURATION.
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
  # for timeslices with TIMESLICE_DURATION.
  def start_dates_backward(wiki)
    start_dates = []
    # There is no guarantee that all wikis are in the same state.
    last_start = CourseWikiTimeslice.max_min_course_start(@course)
    current_start = last_start - timeslice_duration(wiki)
    while current_start >= @course.start
      start_dates << current_start
      current_start -= timeslice_duration(wiki)
    end

    start_dates
  end

  # Returns start dates from the old course end up to the new (later) course end,
  # for timeslices with TIMESLICE_DURATION.
  def start_dates_from_old_end(wiki)
    start_dates = []
    # There is no guarantee that all wikis are in the same state.
    current_start = CourseWikiTimeslice.min_max_course_end(@course)
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

  def delete_article_course_timeslice_ids(ids)
    ids.each_slice(5000) do |slice|
      ArticleCourseTimeslice.where(id: slice).delete_all
    end
  end

  def delete_course_wiki_timeslice_ids(ids)
    ids.each_slice(5000) do |slice|
      CourseWikiTimeslice.where(id: slice).delete_all
    end
  end

  def delete_course_user_wiki_timeslice_ids(ids)
    ids.each_slice(5000) do |slice|
      CourseUserWikiTimeslice.where(id: slice).delete_all
    end
  end
end
