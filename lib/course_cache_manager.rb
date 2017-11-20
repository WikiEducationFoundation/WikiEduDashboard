# frozen_string_literal: true

require "#{Rails.root}/lib/revision_stat"
require "#{Rails.root}/lib/course_training_progress_manager"

#= Service for updating the counts that are cached on Course objects
class CourseCacheManager
  def initialize(course)
    @course = course
  end

  def update_cache
    update_character_sum
    update_view_sum
    update_user_count
    update_trained_count
    update_revision_count
    update_recent_revision_count
    update_article_count
    update_new_article_count
    update_upload_count
    update_uploads_in_use_count
    update_upload_usages_count
    @course.save
  end

  def update_user_count
    @course.user_count = @course.students.size
  end

  private

  ##################
  # Cache updaters #
  ##################

  def update_character_sum
    # Do not consider revisions with negative byte changes
    @course.character_sum = @course.courses_users
                                   .where(role: CoursesUsers::Roles::STUDENT_ROLE)
                                   .sum(:character_sum_ms)
  end

  def update_view_sum
    @course.view_sum = @course.articles_courses.live.sum(:view_count)
  end

  def update_trained_count
    # The cutoff date represents the switch from on-wiki training, indicated by
    # the 'trained' attribute of a User, to the in-dashboard training module
    # system introduced for the beginning of 2016. For courses after the cutoff
    # date, 'trained_count' is represents the count of students who don't have
    # assigned training modules that are overdue.
    trained_count = if past_training_cutoff?
                      @course.students_up_to_date_with_training.count
                    else
                      @course.students.trained.size
                    end
    @course.trained_count = trained_count
  end

  def update_revision_count
    @course.revision_count = @course.revisions.live.size
  end

  def update_recent_revision_count
    @course.recent_revision_count = RevisionStat.get_records(course_id: @course.id)
  end

  def update_article_count
    @course.article_count = @course.articles.namespace(0).live.size
  end

  def update_new_article_count
    @course.new_article_count = @course.new_articles.count
  end

  def update_upload_count
    @course.upload_count = @course.uploads.count
  end

  def update_uploads_in_use_count
    @course.uploads_in_use_count = @course.uploads_in_use.count
  end

  def update_upload_usages_count
    @course.upload_usages_count = @course.uploads_in_use.sum(:usage_count)
  end

  ############
  # Helplers #
  ############

  def past_training_cutoff?
    @course.start > CourseTrainingProgressManager::TRAINING_BOOLEAN_CUTOFF_DATE
  end
end
