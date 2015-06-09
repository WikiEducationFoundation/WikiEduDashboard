#= Utilities for calcuating statistics for course activity
class Analytics
  # For a set of course ids, generate a human-readable summary of what the users
  # in those courses contributed.
  def self.report_statistics(course_ids)
    courses_users = CoursesUsers.where(course_id: course_ids, role: 0)
    student_ids = courses_users.pluck(:user_id).uniq
    characters_added = courses_users.sum(:character_sum_ms)
    revisions = Revision.where(user_id: student_ids)
    revision_ids = revisions.pluck(:id)
    page_ids = revisions.pluck(:article_id).uniq
    article_ids = Article.where(namespace: 0, id: page_ids).pluck(:id)
    new_revisions = Revision.where(user_id: student_ids, new_article: true)
    new_page_ids = new_revisions.pluck(:article_id).uniq
    new_article_ids = Article.where(namespace: 0, id: new_page_ids).pluck(:id)
    upload_ids = CommonsUpload.where(user_id: student_ids).pluck(:id)
    used_uploads = CommonsUpload
                   .where(id: upload_ids)
                   .where('usage_count > 0')
    used_count = used_uploads.count
    usage_count = used_uploads.sum(:usage_count)
    report = %(
#{student_ids.count} students
#{characters_added} characters added
#{revision_ids.count} revisions
#{article_ids.count} articles edited
#{new_article_ids.count} articles created
#{upload_ids.count} files uploaded
#{used_count} files in use
#{usage_count} global usages
    )
    report
  end
end
