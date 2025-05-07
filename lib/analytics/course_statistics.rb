# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"

#= Utilities for calcuating statistics for course activity
class CourseStatistics
  ################
  # Entry points #
  ################

  def initialize(course_ids, opts = {})
    @course_ids = course_ids
    @opts = opts
    # find_contribution_ids
    find_course_counts
    find_upload_ids
    find_upload_usage
    find_user_counts
    find_new_article_ids
    find_edited_article_ids
  end

  # For a set of course ids, generate a human-readable summary of what the users
  # in those courses contributed.
  # rubocop:disable Metrics/MethodLength
  def report_statistics
    report = {
      course_count: @course_ids.uniq.count,
      students_excluding_instructors: @pure_student_ids.count,
      trained_students: @trained_student_count,
      characters_added: @characters_added,
      words_added: @words_added,
      revisions: @revision_count,
      articles_edited: @edited_article_ids.count,
      articles_created: @surviving_article_ids.count,
      articles_deleted: @deleted_article_ids.count,
      references_added: @references_added,
      file_uploads: @upload_ids.count,
      files_in_use: @used_count,
      global_usages: @usage_count,
      cumulative_page_views_estimate: @view_sum
    }

    report = { @opts[:campaign].to_sym => report } if @opts[:campaign]
    report
  end
  # rubocop:enable Metrics/MethodLength

  def articles_edited
    Article.where(namespace: 0, id: @all_article_ids)
  end

  ################
  # Calculations #
  ################

  private

  def find_course_counts
    @courses = Course.where(id: @course_ids)
    @view_sum = @courses.sum(:view_sum)
    @revision_count = @courses.sum(:revision_count)
  end

  def find_upload_ids
    @upload_ids = []
    @courses.each do |course|
      @upload_ids << course.uploads.pluck(:id)
    end
    @upload_ids = @upload_ids.flatten.uniq
  end

  def find_upload_usage
    used_uploads = CommonsUpload.where(id: @upload_ids).where('usage_count > 0')
    @used_count = used_uploads.count
    @upload_count = used_uploads.count
    @usage_count = used_uploads.sum(:usage_count)
  end

  def find_user_counts
    students = CoursesUsers.where(course_id: @course_ids, role: 0)
    @student_ids = students.pluck(:user_id).uniq
    @characters_added = students.sum(:character_sum_ms)
    @words_added = WordCount.from_characters(@characters_added)
    @references_added = students.sum(:references_count)
    nonstudents = CoursesUsers.where(course_id: @course_ids, role: [1, 2, 3, 4])
    @nonstudent_ids = nonstudents.pluck(:user_id).uniq
    @pure_student_ids = @student_ids - @nonstudent_ids
    @trained_student_count = User.where(id: @pure_student_ids, trained: true).count
  end

  def find_new_article_ids
    new_article_ids = []
    @courses.each do |course|
      new_article_ids += course.tracked_article_course_timeslices
                               .where('revision_count > 0')
                               .where(new_article: true)
                               .pluck(:article_id)
                               .uniq
    end

    created_articles = Article.where(namespace: 0, id: new_article_ids)
    @surviving_article_ids = created_articles.where(deleted: false).pluck(:id)
    @deleted_article_ids = created_articles.where(deleted: true).pluck(:id)
  end

  def find_edited_article_ids
    @all_article_ids = []
    @courses.each do |course|
      @all_article_ids += course.tracked_article_course_timeslices
                                .where('revision_count > 0')
                                .pluck(:article_id)
                                .uniq
    end
    @edited_article_ids = Article.where(namespace: 0, id: @all_article_ids,
                                        deleted: false).pluck(:id)
  end
end
