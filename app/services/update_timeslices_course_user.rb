# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_cleaner"
require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner"
require_dependency "#{Rails.root}/lib/revision_data_manager"
require_dependency "#{Rails.root}/lib/course_revision_updater"

class UpdateTimeslicesCourseUser
  def initialize(course, update_service: nil)
    @course = course
    @timeslice_cleaner = TimesliceCleaner.new(course)
    @timeslice_manager = TimesliceManager.new(course)
    @update_service = update_service
  end

  def run
    # If this is the first course update, then we don't need to update course user timeslices
    return unless @course.was_course_ever_updated?
    # Get the existing students in the course (we don't create timeslices for non-students)
    current_user_ids = @course.students.pluck(:id)

    # Users for whose exist a course user timeslice are considered processed
    processed_users = CourseUserWikiTimeslice.where(course: @course)
                                             .select(:user_id).distinct.pluck(:user_id)

    deleted_user_ids = processed_users - current_user_ids
    remove_courses_users(deleted_user_ids)

    # Users that were added after the last course update start are considered new
    # It's not safe to rely on new_user_ids = current_user_ids - processed_users
    @course_update_start = @course.last_update_start_time
    new_user_ids = @course.students.where('courses_users.created_at >= ?',
                                          @course_update_start).pluck(:id)
    add_user_ids(new_user_ids)
  end

  private

  def add_user_ids(user_ids)
    return if user_ids.empty?

    Rails.logger.info "UpdateTimeslicesCourseUser: Course: #{@course.slug}\
    Adding new users: #{user_ids}"

    if @course.use_acuwt?
      add_user_ids_acuwt(user_ids)
    else
      add_user_ids_legacy(user_ids)
      update_created_at_for_users(user_ids)
    end
  end

  # Update created_at field for courses users to prevent re-marking them as newly added
  def update_created_at_for_users(user_ids)
    @course.courses_users.where(user_id: user_ids)
           .update_all(created_at: @course_update_start - 1.second) # rubocop:disable Rails/SkipsModelValidations
  end

  def add_user_ids_legacy(user_ids)
    @course.wikis.each do |wiki|
      fetch_users_revisions_for_wiki(wiki, user_ids)
    end
  end

  # Process new users one at a time, marking each as no-longer-new as soon as all their
  # revisions were processed, so that an interrupted update doesn't redo completed users.
  # If processing fails for some wiki, the user stays new (to be retried next update),
  # so we skip their remaining wikis instead of doing work that would be redone anyway.
  def add_user_ids_acuwt(user_ids)
    user_ids.each do |user_id|
      user = User.find(user_id)
      failed = false
      @course.wikis.each do |wiki|
        fetch_and_create_acuwt_for_new_user(wiki, user)
      rescue StandardError => e
        failed = true
        log_user_processing_error(e, user_id, wiki.id)
        break
      end
      update_created_at_for_users([user_id]) unless failed
    end
  end

  # Fetch the new user's revisions one course wiki timeslice at a time, so that a single
  # fetch/processing pass is never bigger than what the timeslice splitting already
  # determined this course can handle.
  def fetch_and_create_acuwt_for_new_user(wiki, user)
    updater = CourseRevisionUpdater.new(@course, update_service: @update_service)
    timeslices_to_process(wiki).each do |cwt|
      revisions = updater.fetch_revisions_for_new_users(
        wiki, [user], real_start(cwt.start), real_end(cwt.end)
      )
      next if revisions.empty?

      create_acuwt_records_for_timeslice(wiki, cwt, revisions)
      CourseWikiTimeslice.where(id: cwt.id)
                         .update_all(needs_reaggregation: true) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # Every timeslice up to the current ingestion limit. Future timeslices can't
  # contain revisions yet, so fetching them would be wasted requests.
  def timeslices_to_process(wiki)
    timeslices = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
    latest_start = @timeslice_manager.get_latest_start_time_for_wiki(wiki)
    latest_start ? timeslices.where('start <= ?', latest_start) : timeslices
  end

  def real_start(timeslice_start)
    [timeslice_start, @course.start].max.strftime('%Y%m%d%H%M%S')
  end

  # Replica treats both bounds as inclusive, so subtract a second from the timeslice
  # end to avoid fetching boundary revisions for two adjacent timeslices.
  def real_end(timeslice_end)
    [timeslice_end - 1.second, @course.end].min.strftime('%Y%m%d%H%M%S')
  end

  def log_user_processing_error(error, user_id, wiki_id)
    Sentry.capture_message "#{@course.slug} new user processing error: #{error}",
                           level: 'error',
                           extra: { course_id: @course.id, user_id:, wiki_id: }
  end

  def create_acuwt_records_for_timeslice(wiki, cwt, revisions)
    ArticleCourseUserWikiTimeslice.bulk_upsert_from_revisions(
      @course, wiki, cwt.start, cwt.end, revisions
    )
  end

  def fetch_users_revisions_for_wiki(wiki, user_ids)
    users = User.find(user_ids)

    manager = RevisionDataManager.new(wiki, @course, update_service: @update_service)
    # Fetch the revisions for users for the complete period
    revisions = manager.fetch_revision_data_for_users(users,
                                                      @course.start.strftime('%Y%m%d%H%M%S'),
                                                      @course.end.strftime('%Y%m%d%H%M%S'))
    @timeslice_manager.update_timeslices_that_need_update_from_revisions(revisions, wiki)
  end

  def remove_courses_users(user_ids)
    return if user_ids.empty?

    Rails.logger.info "UpdateTimeslicesCourseUser: Course: #{@course.slug}\
    Removing old users: #{user_ids}"

    if @course.use_acuwt?
      remove_courses_users_acuwt(user_ids)
    else
      remove_courses_users_legacy(user_ids)
    end
  end

  def remove_courses_users_legacy(user_ids)
    # Delete course user wiki timeslices for the deleted users
    @timeslice_cleaner.delete_course_user_timeslices_for_deleted_course_users user_ids

    # Do this to avoid running the query twice
    @article_course_timeslices_for_users = get_article_course_timeslices_for_users(user_ids)
    # Mark course wiki timeslices that needs to be re-processed
    @timeslice_cleaner.reset_timeslices_that_need_update_from_article_timeslices(
      @article_course_timeslices_for_users
    )
    # Delete articles courses that were updated only for removed users
    ArticlesCoursesCleaner.clean_articles_courses_for_user_ids(@course, user_ids)
  end

  def remove_courses_users_acuwt(user_ids)
    acuwt_records = ArticleCourseUserWikiTimeslice.where(course: @course, user_id: user_ids)
    # Marks CWT as needs_reaggregation; deletes ACT and CUWT rows for affected periods
    @timeslice_cleaner.reset_timeslices_for_reaggregation_from_acuwt(acuwt_records)
    # Delete ACUWT records for removed users
    @timeslice_cleaner.delete_acuwt_for_deleted_course_users(user_ids)
    # Delete articles courses that were updated only for removed users
    ArticlesCoursesCleaner.clean_articles_courses_for_user_ids(@course, user_ids)
  end

  # Returns an ArticleCourseTimeslice relation with edits from the given users
  def get_article_course_timeslices_for_users(user_ids)
    return ArticleCourseTimeslice.none if user_ids.empty?

    # These are the ArticleCourseTimeslice records that were updated by users
    user_ids.map { |user_id| ArticleCourseTimeslice.search_by_course_and_user(@course, user_id) }
            .reduce(:or)
  end
end
