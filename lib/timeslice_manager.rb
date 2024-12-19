# frozen_string_literal: true

#= Creates/Removes/Updates ArticleCourseTimeslice, CourseUserWikiTimeslice
# and CourseWikiTimeslice records.
class TimesliceManager # rubocop:disable Metrics/ClassLength
  def initialize(course)
    @course = course
  end

  # Deletes course user wiki timeslices records for removed course users
  # Takes a collection of user ids
  def delete_course_user_timeslices_for_deleted_course_users(user_ids)
    return if user_ids.empty?

    timeslice_ids = CourseUserWikiTimeslice.where(course: @course, user_id: user_ids).pluck(:id)

    return if timeslice_ids.empty?

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |slice|
      CourseUserWikiTimeslice.where(id: slice).delete_all
    end
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

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      CourseWikiTimeslice.where(id: timeslice_id_slice).delete_all
    end
  end

  # Deletes course wiki timeslices records with a start date later than the current end date
  def delete_course_wiki_timeslices_after_end_date
    # Delete course wiki timeslices
    timeslice_ids = CourseWikiTimeslice.where(course: @course)
                                       .where('start > ?', @course.end)
                                       .pluck(:id)

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      CourseWikiTimeslice.where(id: timeslice_id_slice).delete_all
    end
  end

  # Deletes course user wiki timeslices records with a date prior to the current start date
  def delete_course_user_wiki_timeslices_prior_to_start_date
    # Delete course user wiki timeslices
    timeslice_ids = CourseUserWikiTimeslice.where(course: @course)
                                           .where('end <= ?', @course.start)
                                           .pluck(:id)

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      CourseUserWikiTimeslice.where(id: timeslice_id_slice).delete_all
    end
  end

  # Deletes course user wiki timeslices records with a start date later than the current end date
  def delete_course_user_wiki_timeslices_after_end_date
    # Delete course user wiki timeslices
    timeslice_ids = CourseUserWikiTimeslice.where(course: @course)
                                           .where('start > ?', @course.end)
                                           .pluck(:id)

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      CourseUserWikiTimeslice.where(id: timeslice_id_slice).delete_all
    end
  end

  # Creates course user timeslices records for every course wiki for new course users
  # Takes an array of CoursesUsers records
  def create_timeslices_for_new_course_user_records(courses_users)
    create_empty_course_user_wiki_timeslices(start_dates, courses_users:)
  end

  # Creates course wiki timeslices records for new course wikis
  # Creates course user timeslices records for new course wiki
  # Takes a collection of Wikis
  def create_timeslices_for_new_course_wiki_records(wikis)
    courses_wikis = @course.courses_wikis.where(wiki: wikis)
    create_empty_course_wiki_timeslices(start_dates, courses_wikis)
    create_empty_course_user_wiki_timeslices(start_dates, courses_wikis:)
  end

  # Creates course wiki timeslices records for missing timeslices due to a change in the start date
  # Creates course user wiki timeslices records for missing timeslices
  def create_timeslices_for_new_course_start_date
    courses_wikis = @course.courses_wikis
    # order matters
    create_empty_course_user_wiki_timeslices(start_dates_backward)
    create_empty_course_wiki_timeslices(start_dates_backward, courses_wikis, needs_update: true)
  end

  # Creates course wiki timeslices records for missing timeslices due to a change in the end date
  # Creates course user wiki timeslices records for missing timeslices
  def create_timeslices_up_to_new_course_end_date
    courses_wikis = @course.courses_wikis
    # order matters
    create_empty_course_user_wiki_timeslices(start_dates_from_old_end)
    create_empty_course_wiki_timeslices(start_dates_from_old_end, courses_wikis, needs_update: true)
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

  # Returns (wiki, start) tuples for timeslices to reprocess
  def get_wiki_and_start_dates_to_reprocess(article_course_timeslices)
    # Extract article IDs and start dates as unique pairs
    articles_and_starts = article_course_timeslices.map do |timeslice|
      [timeslice.article_id, timeslice.start.strftime('%Y-%m-%d %H:%M:%S')]
    end.uniq

    # Fetch articles and map article IDs to their corresponding wiki IDs
    id_to_wiki_map = Article.where(id: articles_and_starts.map(&:first))
                            .index_by(&:id)
                            .transform_values(&:wiki_id)

    # Return unique combinations of wiki IDs and start dates
    articles_and_starts.map { |article_id, start| [id_to_wiki_map[article_id], start] }.uniq
  end

  # Marks course wiki timeslices as needs_update for those dates when
  # removed/new users made some edits
  # Takes a collection of user ids
  def update_course_wiki_timeslices_that_need_update(wikis_and_starts)
    return if wikis_and_starts.empty?

    # Prepare the list of tuples for SQL
    tuples_list = wikis_and_starts.map do |wiki_id, start_date|
      "(#{wiki_id}, '#{start_date}')"
    end.join(', ')

    # Perform the query using raw SQL for specific (wiki_id, start_date) pairs
    course_wiki_timeslices = CourseWikiTimeslice.where(course: @course)
                                                .where("(wiki_id, start) IN (#{tuples_list})")

    # Update all CourseWikiTimeslice records with matching course, wiki and start dates
    course_wiki_timeslices.update_all(needs_update: true) # rubocop:disable Rails/SkipsModelValidations
  end

  TIMESLICE_DURATION = 1.day

  private

  # Creates empty article course timeslices
  # Takes an array like the following:
  # [{:article_id=>115, :course_id=>72},..., {:article_id=>116, :course_id=>72}]
  def create_empty_article_course_timeslices(starts, articles_courses)
    new_records = starts.map do |start|
      articles_courses.map do |a_c|
        tracked = a_c[:tracked].nil? || a_c[:tracked]
        { article_id: a_c[:article_id], course_id: a_c[:course_id], start:,
          end: start + TIMESLICE_DURATION, tracked: }
      end
    end.flatten

    return if new_records.empty?
    # Do this in batches to avoid running the MySQL server out of memory
    new_records.each_slice(5000) do |new_record_slice|
      ArticleCourseTimeslice.import new_record_slice, on_duplicate_key_ignore: true
    end
  end

  # Creates empty course user wiki timeslices
  def create_empty_course_user_wiki_timeslices(starts, courses_users: nil, courses_wikis: nil)
    # Only create course user wiki timeslices for students
    courses_users ||= @course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE)
    courses_wikis ||= @course.courses_wikis
    new_records = starts.map do |start|
      courses_users.map do |c_u|
        courses_wikis.map do |c_w|
          { course_id: c_u.course_id, user_id: c_u.user_id, wiki_id: c_w.wiki_id, start:,
            end: start + TIMESLICE_DURATION }
        end
      end
    end.flatten

    import_new_course_user_wiki_records new_records
  end

  def import_new_course_user_wiki_records(new_records)
    return if new_records.empty?
    # Do this in batches to avoid running the MySQL server out of memory
    new_records.each_slice(5000) do |new_record_slice|
      CourseUserWikiTimeslice.import new_record_slice, on_duplicate_key_ignore: true
    end
  end

  # Creates empty course wiki timeslices
  def create_empty_course_wiki_timeslices(starts, courses_wikis, needs_update: false)
    new_records = starts.map do |start|
      courses_wikis.map do |c_w|
        { course_id: @course.id, wiki_id: c_w.wiki_id, start:, end: start + TIMESLICE_DURATION,
          needs_update: }
      end
    end.flatten

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

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      CourseWikiTimeslice.where(id: timeslice_id_slice).delete_all
    end
  end

  # Deletes existing course user wiki timeslices for a collection of wiki ids
  def delete_existing_course_user_wiki_timeslices(wiki_ids)
    # Collect the ids of timeslices to be deleted
    timeslice_ids = CourseUserWikiTimeslice.where(course_id: @course.id,
                                                  wiki_id: wiki_ids).pluck(:id)

    return if timeslice_ids.empty?

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      CourseUserWikiTimeslice.where(id: timeslice_id_slice).delete_all
    end
  end

  # Deletes existing article course timeslices for a collection of wiki ids
  def delete_existing_article_course_timeslices(wiki_ids)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles.where(wiki_id: wiki_ids).pluck(:id)

    # Collect the ids of timeslices to be deleted
    timeslice_ids = ArticleCourseTimeslice.where(course_id: @course.id,
                                                 article_id: article_ids).pluck(:id)

    return if timeslice_ids.empty?

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      ArticleCourseTimeslice.where(id: timeslice_id_slice).delete_all
    end
  end

  # Returns start dates from the course start up to course end, for timeslices with
  # TIMESLICE_DURATION.
  def start_dates
    start_dates = []
    current_start = @course.start
    while current_start <= @course.end
      start_dates << current_start
      current_start += TIMESLICE_DURATION
    end

    start_dates
  end

  # Returns start dates from the old course start up to the new (previous) course start,
  # for timeslices with TIMESLICE_DURATION.
  def start_dates_backward
    start_dates = []
    # There is no guarantee that all wikis are in the same state.
    last_start = CourseWikiTimeslice.max_min_course_start(@course)
    current_start = last_start - TIMESLICE_DURATION
    while current_start >= @course.start
      start_dates << current_start
      current_start -= TIMESLICE_DURATION
    end

    start_dates
  end

  # Returns start dates from the old course end up to the new (later) course end,
  # for timeslices with TIMESLICE_DURATION.
  def start_dates_from_old_end
    start_dates = []
    # There is no guarantee that all wikis are in the same state.
    last_start = CourseWikiTimeslice.min_max_course_start(@course)
    current_start = last_start + TIMESLICE_DURATION
    while current_start <= @course.end
      start_dates << current_start
      current_start += TIMESLICE_DURATION
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
