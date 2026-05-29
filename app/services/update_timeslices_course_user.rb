# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_cleaner"
require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"
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
    @course_update_start = @course.flags['update_logs'].values.last['start_time']
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
    end
    # Update created_at field for courses users to prevent re-marking them as newly added
    @course.courses_users.where(user_id: user_ids)
           .update_all(created_at: @course_update_start - 1.second) # rubocop:disable Rails/SkipsModelValidations
  end

  def add_user_ids_legacy(user_ids)
    @course.wikis.each do |wiki|
      fetch_users_revisions_for_wiki(wiki, user_ids)
    end
  end

  def add_user_ids_acuwt(user_ids)
    @course.wikis.each do |wiki|
      fetch_and_create_acuwt_for_new_users(wiki, user_ids)
    end
  end

  def fetch_and_create_acuwt_for_new_users(wiki, user_ids)
    updater = CourseRevisionUpdater.new(@course, update_service: @update_service)
    revisions = updater.fetch_revisions_for_new_users(
      wiki, User.find(user_ids),
      @course.start.strftime('%Y%m%d%H%M%S'),
      @course.end.strftime('%Y%m%d%H%M%S')
    )
    mark_timeslices_and_create_acuwt(wiki, revisions) if revisions.any?
  end

  def mark_timeslices_and_create_acuwt(wiki, revisions)
    needs_reaggregation_ids = []
    CourseWikiTimeslice.for_course_and_wiki(@course, wiki).each do |cwt|
      revs_in_period = revisions.select { |r| cwt.start <= r.date && r.date < cwt.end }
      next if revs_in_period.empty?

      create_acuwt_records_for_timeslice(wiki, cwt, revs_in_period)
      needs_reaggregation_ids << cwt.id
    end
    return if needs_reaggregation_ids.empty?

    CourseWikiTimeslice.where(id: needs_reaggregation_ids)
                       .update_all(needs_reaggregation: true) # rubocop:disable Rails/SkipsModelValidations
  end

  def create_acuwt_records_for_timeslice(wiki, cwt, revisions)
    revisions.group_by { |r| [r.article_id, r.user_id] }.each do |(article_id, user_id), revs|
      next if article_id.nil? || user_id.nil?

      article_user_wiki_data = { start: cwt.start, end: cwt.end, revisions: revs }
      ArticleCourseUserWikiTimeslice.update_article_course_user_wiki_timeslices(
        @course, article_id, user_id, wiki, article_user_wiki_data
      )
    end
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
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_for_user_ids(@course, user_ids)
  end

  def remove_courses_users_acuwt(user_ids)
    acuwt_records = ArticleCourseUserWikiTimeslice.where(course: @course, user_id: user_ids)
    # Marks CWT as needs_reaggregation; deletes targeted ACT rows for affected articles
    @timeslice_cleaner.reset_timeslices_for_reaggregation_from_acuwt(acuwt_records)
    # Delete course user wiki timeslices for removed users
    @timeslice_cleaner.delete_course_user_timeslices_for_deleted_course_users(user_ids)
    # Delete ACUWT records for removed users
    @timeslice_cleaner.delete_acuwt_for_deleted_course_users(user_ids)
    # Delete articles courses that were updated only for removed users
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_for_user_ids(@course, user_ids)
  end

  # Returns ArticleCourseTimeslice records that have edits from users
  def get_article_course_timeslices_for_users(user_ids)
    timeslices = user_ids.map do |user_id|
      ArticleCourseTimeslice.search_by_course_and_user(@course, user_id)
    end

    # These are the ArticleCourseTimeslice records that were updated by users
    timeslices.flatten
  end
end
