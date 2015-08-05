#= Utilities for calcuating statistics for course activity
class Analytics
  # For a set of course ids, generate a human-readable summary of what the users
  # in those courses contributed.
  def self.report_statistics(course_ids)
    students = CoursesUsers.where(course_id: course_ids, role: 0)
    nonstudents = CoursesUsers.where(course_id: course_ids, role: [1,2,3,4])
    nonstudent_ids = nonstudents.pluck(:user_id).uniq
    student_ids = students.pluck(:user_id).uniq
    pure_student_ids = student_ids - nonstudent_ids
    characters_added = courses_users.sum(:character_sum_ms)
    revisions = Revision.where(user_id: pure_student_ids)
    revision_ids = revisions.pluck(:id)
    page_ids = revisions.pluck(:article_id).uniq
    article_ids = Article.where(namespace: 0, id: page_ids).pluck(:id)
    # Note that these calculations may include revisions from outside the scope
    # of the target course_ids, for example from earlier terms.
    new_revisions = Revision.where(user_id: pure_student_ids, new_article: true)
    new_page_ids = new_revisions.pluck(:article_id).uniq
    created_articles = Article.where(namespace: 0, id: new_page_ids)
    surviving_article_ids = created_articles.where(deleted: false).pluck(:id)
    deleted_article_ids = created_articles.where(deleted: true).pluck(:id)
    upload_ids = CommonsUpload.where(user_id: pure_student_ids).pluck(:id)
    used_uploads = CommonsUpload
                   .where(id: upload_ids)
                   .where('usage_count > 0')
    used_count = used_uploads.count
    usage_count = used_uploads.sum(:usage_count)
    report = %(
#{pure_student_ids.count} students (excluding instructors)
#{characters_added} characters added
#{revision_ids.count} revisions
#{article_ids.count} articles edited
#{surviving_article_ids.count} articles created
#{deleted_article_ids.count} articles deleted
#{upload_ids.count} files uploaded
#{used_count} files in use
#{usage_count} global usages
    )
    report
  end
end
