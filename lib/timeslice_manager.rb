# frozen_string_literal: true

#= Creates/Removes/Updates ArticleCourseTimeslice, CourseUserWikiTimeslice
# and CourseWikiTimeslice records.
class TimesliceManager # rubocop:disable Metrics/ClassLength
  def initialize(course)
    @course = course
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

  # Creates article course timeslices records for new articles courses
  # Takes an array like the following:
  # [{:article_id=>115, :course_id=>72},..., {:article_id=>116, :course_id=>72}]
  def create_timeslices_for_new_article_course_records(articles_courses)
    create_empty_article_course_timeslices(articles_courses)
  end

  # Creates course user timeslices records for every course wiki for new course users
  # Takes an array of CoursesUsers records
  def create_timeslices_for_new_course_user_records(courses_users)
    create_empty_course_user_wiki_timeslices(courses_users:)
  end

  # Creates course wiki timeslices records for new course wikis
  # Creates course user timeslices records for new course wiki
  # Takes a collection of Wikis
  def create_timeslices_for_new_course_wiki_records(wikis)
    courses_wikis = @course.courses_wikis.where(wiki: wikis)
    create_empty_course_wiki_timeslices(courses_wikis)
    create_empty_course_user_wiki_timeslices(courses_wikis:)
  end

  # Returns a string with the date to start getting revisions.
  # For example: '20181124000000'
  def get_last_mw_rev_datetime_for_wiki(wiki)
    non_empty_timeslices = @course.course_wiki_timeslices.where(wiki:).reject do |ts|
      ts.last_mw_rev_datetime.nil?
    end
    last_datetime = non_empty_timeslices.max_by(&:last_mw_rev_datetime)&.last_mw_rev_datetime

    last_datetime ||= @course.start
    last_datetime.strftime('%Y%m%d%H%M%S')
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

  private

  TIMESLICE_DURATION = 1.day

  # Creates empty article course timeslices
  # Takes an array like the following:
  # [{:article_id=>115, :course_id=>72},..., {:article_id=>116, :course_id=>72}]
  def create_empty_article_course_timeslices(articles_courses)
    new_records = start_dates.map do |start|
      articles_courses.map do |a_c|
        { article_id: a_c[:article_id], course_id: a_c[:course_id], start:,
          end: start + TIMESLICE_DURATION }
      end
    end.flatten

    return if new_records.empty?
    # Do this in batches to avoid running the MySQL server out of memory
    new_records.each_slice(5000) do |new_record_slice|
      ArticleCourseTimeslice.import new_record_slice
    end
  end

  # Creates empty course user wiki timeslices
  def create_empty_course_user_wiki_timeslices(courses_users: nil, courses_wikis: nil)
    courses_users ||= @course.courses_users
    courses_wikis ||= @course.courses_wikis
    new_records = start_dates.map do |start|
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
      CourseUserWikiTimeslice.import new_record_slice
    end
  end

  # Creates empty course wiki timeslices
  def create_empty_course_wiki_timeslices(courses_wikis)
    new_records = start_dates.map do |start|
      courses_wikis.map do |c_w|
        { course_id: @course.id, wiki_id: c_w.wiki_id, start:, end: start + TIMESLICE_DURATION }
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

  def start_dates
    start_dates = []
    # Create timeslices for 3 days before the course start day.
    current_start = @course.start - 3.days
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

  def get_course_wiki_timeslice(wiki, datetime)
    CourseWikiTimeslice.for_course_and_wiki(@course, wiki).for_datetime(datetime).first
  end

  def get_course_wiki_timeslices(wiki, period_start, period_end)
    CourseWikiTimeslice.for_course_and_wiki(@course, wiki).in_period(period_start, period_end)
  end
end
