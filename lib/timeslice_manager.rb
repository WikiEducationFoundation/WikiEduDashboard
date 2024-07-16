# frozen_string_literal: true

#= Adds new ArticleCourseTimeslice, CourseUserWikiTimeslice and CourseWikiTimeslice records.
class TimesliceManager
  def initialize(course)
    @course = course
  end

  # Creates article course timeslices records for new articles courses
  def create_timeslices_for_new_article_course_records(articles_courses)
    create_empty_article_course_timeslices(articles_courses)
  end

  # Creates course user timeslices records for every course wiki for new course users
  def create_timeslices_for_new_course_user_records(courses_users)
    create_empty_course_user_wiki_timeslices(courses_users:)
  end

  # Creates course wiki timeslices records for new course wikis
  # Creates course user timeslices records for new course wiki
  def create_timeslices_for_new_course_wiki_records(courses_wikis)
    create_empty_course_wiki_timeslices(courses_wikis)
    create_empty_course_user_wiki_timeslices(courses_wikis:)
  end

  def update_course_article_timeslice
    ArticleCourseTimeslice.find_or_create_by(
      article_id:,
      course: @course,
      start: @timeslice_start.to_datetime,
      end: @timeslice_end.to_datetime
    ).update_cache_from_revisions article_revisions
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
        { course_id: c_w.course_id, wiki_id: c_w.wiki_id, start:, end: start + TIMESLICE_DURATION }
      end
    end.flatten

    return if new_records.empty?
    # Do this in batches to avoid running the MySQL server out of memory
    new_records.each_slice(5000) do |new_record_slice|
      CourseWikiTimeslice.import new_record_slice
    end
  end

  def start_dates
    start_dates = []
    current_start = @course.start
    while current_start <= @course.end
      start_dates << current_start
      current_start += TIMESLICE_DURATION
    end

    start_dates
  end
end
