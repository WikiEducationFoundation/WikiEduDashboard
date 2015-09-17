#= Utilities for calcuating statistics for course activity
class CourseStatistics
  # For a set of course ids, generate a human-readable summary of what the users
  # in those courses contributed.
  class << self
    def report_statistics(course_ids, opts = {})
      @@course_ids = course_ids
      report = {
        course_count: course_ids.uniq.count,
        students_excluding_instructors: pure_student_ids.count,
        trained_students: trained_student_count,
        characters_added: characters_added,
        revisions: revision_ids.count,
        articles_edited: article_ids.count,
        articles_created: surviving_article_ids.count,
        articles_deleted: deleted_article_ids.count,
        files_uploads: upload_ids.count,
        files_in_use: used_count,
        global_usages: usage_count
      }

      report = { opts[:cohort].to_sym => report } if opts[:cohort]
      report
    end

    def articles_edited(course_ids)
      @@course_ids = course_ids
      Article.where(namespace: 0, id: page_ids)
    end

    private

    def students
      CoursesUsers.where(course_id: @@course_ids, role: 0)
    end

    def nonstudents
      CoursesUsers.where(course_id: @@course_ids, role: [1, 2, 3, 4])
    end

    def nonstudent_ids
      nonstudents.pluck(:user_id).uniq
    end

    def student_ids
      students.pluck(:user_id).uniq
    end

    def pure_student_ids
      student_ids - nonstudent_ids
    end

    def trained_student_count
      User.where(id: pure_student_ids, trained: true).count
    end

    def characters_added
      students.sum(:character_sum_ms)
    end

    def revisions
      # Note that these may include revisions from outside the scope
      # of the target course_ids, for example from earlier terms.
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

  # def self.article_quality(courses)
  #   puts 'course,article,revision,score'
  #   courses.each do |course|
  #     articles = course.articles.namespace(0)
  #     articles.each do |article|
  #       revisions = article.revisions
  #       first_rev = revisions.first
  #       puts '"' + course.title + '","' +
  #         article.title + '","' + first_rev.id.to_s +
  #         'prev",' + first_rev.wp10_previous.to_s
  #       revisions.each do |revision|
  #         puts '"' + course.title + '","' +
  #           article.title + '","' +
  #           revision.id.to_s + '",' +
  #           revision.wp10.to_s
  #       end
  #     end
  #   end
  # end
end
