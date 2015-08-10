#= Utilities for calcuating statistics for course activity
class Analytics
  # For a set of course ids, generate a human-readable summary of what the users
  # in those courses contributed.
  class << self

    def report_statistics(course_ids)
      @@course_ids = course_ids
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

    private


    def students
      CoursesUsers.where(course_id: @@course_ids, role: 0)
    end

    def nonstudents
      CoursesUsers.where(course_id: @@course_ids, role: [1,2,3,4])
    end

    def nonstudent_ids
      nonstudents.pluck(:user_id).uniq
    end

    def student_ids
      student_ids = students.pluck(:user_id).uniq
    end

    def pure_student_ids
      student_ids - nonstudent_ids
    end

    def characters_added
      CoursesUsers.sum(:character_sum_ms)
    end

    def revisions
      Revision.where(user_id: pure_student_ids)
    end

    def revision_ids
      revisions.pluck(:id)
    end

    def page_ids
      revisions.pluck(:article_id).uniq
    end

    def article_ids
      Article.where(namespace: 0, id: page_ids).pluck(:id)
    end

    def new_revisions
      Revision.where(user_id: pure_student_ids, new_article: true)
    end

    def new_page_ids
      new_revisions.pluck(:article_id).uniq
    end

    def created_articles
      Article.where(namespace: 0, id: new_page_ids)
    end

    def surviving_article_ids
      created_articles.where(deleted: false).pluck(:id)
    end

    def deleted_article_ids
      created_articles.where(deleted: true).pluck(:id)
    end

    # Note that these calculations may include revisions from outside the scope
    # of the target course_ids, for example from earlier terms.
    def upload_ids
      CommonsUpload.where(user_id: pure_student_ids).pluck(:id)
    end

    def used_uploads
      CommonsUpload .where(id: upload_ids) .where('usage_count > 0')
    end

    def used_count
      used_uploads.count
    end

    def usage_count
      used_uploads.sum(:usage_count)
    end
  end

end
