#= Utilities for calcuating statistics for course activity
class CourseStatistics
  ################
  # Entry points #
  ################

  def initialize(course_ids, opts = {})
    @course_ids = course_ids
    @opts = opts
    find_contribution_ids
    find_upload_usage
    find_user_counts
    find_article_counts
  end

  # For a set of course ids, generate a human-readable summary of what the users
  # in those courses contributed.
  def report_statistics
    report = {
      course_count: @course_ids.uniq.count,
      students_excluding_instructors: @pure_student_ids.count,
      trained_students: @trained_student_count,
      characters_added: @characters_added,
      revisions: @revision_ids.count,
      articles_edited: @article_ids.count,
      articles_created: @surviving_article_ids.count,
      articles_deleted: @deleted_article_ids.count,
      file_uploads: @upload_ids.count,
      files_in_use: @used_count,
      global_usages: @usage_count
    }

    report = { @opts[:cohort].to_sym => report } if @opts[:cohort]
    report
  end

  def articles_edited
    Article.where(namespace: 0, id: @article_ids)
  end

  ################
  # Calculations #
  ################

  private

  def find_contribution_ids
    revision_ids = []
    article_ids = []
    upload_ids = []

    @course_ids.each do |course_id|
      course = Course.find(course_id)
      revisions = course.revisions
      revision_ids << revisions.pluck(:id)
      article_ids << revisions.pluck(:article_id)
      upload_ids << course.uploads.pluck(:id)
    end
    @revision_ids = revision_ids.flatten.uniq
    @article_ids = article_ids.flatten.uniq
    @upload_ids = upload_ids.flatten.uniq
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
    nonstudents = CoursesUsers.where(course_id: @course_ids, role: [1, 2, 3, 4])
    @nonstudent_ids = nonstudents.pluck(:user_id).uniq
    @pure_student_ids = @student_ids - @nonstudent_ids
    @trained_student_count = User.where(id: @pure_student_ids, trained: true).count
  end

  def find_article_counts
    new_revisions = Revision.where(id: @revision_ids, new_article: true)
    new_article_ids = new_revisions.pluck(:article_id).uniq
    created_articles = Article.where(namespace: 0, id: new_article_ids)

    @surviving_article_ids = created_articles.where(deleted: false).pluck(:id)
    @deleted_article_ids = created_articles.where(deleted: true).pluck(:id)
  end
end
