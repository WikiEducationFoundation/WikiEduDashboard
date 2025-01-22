# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"
require_dependency "#{Rails.root}/lib/revision_data_manager"

class UpdateTimeslicesCourseUser
  def initialize(course, update_service: nil)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
    @update_sercice = update_service
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
    course_update_start = @course.flags['update_logs'].values.last['start_time']
    new_user_ids = @course.students.where('courses_users.created_at >= ?',
                                          course_update_start).pluck(:id)
    add_user_ids(new_user_ids)
  end

  private

  def add_user_ids(user_ids)
    return if user_ids.empty?

    Rails.logger.info "UpdateTimeslicesCourseUser: Course: #{@course.slug}\
    Adding new users: #{user_ids}"

    @course.wikis.each do |wiki|
      fetch_users_revisions_for_wiki(wiki, user_ids)
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
    # Delete course user wiki timeslices for the deleted users
    @timeslice_manager.delete_course_user_timeslices_for_deleted_course_users user_ids

    # Do this to avoid running the query twice
    @article_course_timeslices_for_users = get_article_course_timeslices_for_users(user_ids)
    # Mark course wiki timeslices that needs to be re-proccesed
    @timeslice_manager.reset_timeslices_that_need_update_from_article_timeslices(
      @article_course_timeslices_for_users
    )
    # Clean articles courses timeslices
    # clean_article_course_timeslices
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

  # def clean_article_course_timeslices
  #   ids = @article_course_timeslices_for_users.map(&:id)
  #   ArticleCourseTimeslice.where(id: ids).update_all(character_sum: 0,
  #                                                    references_count: 0,
  #                                                    user_ids: nil)
  # end
end
