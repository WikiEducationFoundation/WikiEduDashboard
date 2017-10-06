# frozen_string_literal: true

#= Utilities for calcuating statistics by month, and year-over-year
class MonthlyReport
  def self.run(opts={})
    new(opts).report
  end

  def initialize(opts)
    @month = opts[:month] || 1.month.ago.month
    @year = opts[:year] || Time.zone.now.year
    @last_year = @year - 1
    set_courses && set_articles && set_uploads
  end

  def report
    { "#{@year}-#{@month}".to_sym =>
        { articles_edited: @articles_edited,
          uploads: @uploads },
      "#{@last_year}-#{@month}".to_sym =>
        { articles_edited: @old_articles_edited,
          uploads: @old_uploads } }
  end

  private

  def set_courses
    @courses = courses_during(@month, @year)
    @old_courses = courses_during(@month, @last_year)
  end

  def set_articles
    @articles_edited = monthly_articles_edited_for(@courses, @month, @year)
    @old_articles_edited = monthly_articles_edited_for(@old_courses, @month, @last_year)
  end

  def set_uploads
    @uploads = monthly_uploads_for(@courses, @month, @year)
    @old_uploads = monthly_uploads_for(@old_courses, @month, @last_year)
  end

  ####################
  # Helper functions #
  ####################

  def courses_during(month, year)
    Course
      .where('start < ?', Date.civil(year, month, -1))
      .where('end > ?', Date.civil(year, month, 1))
  end

  def monthly_articles_edited_for(courses, month, year)
    revisions = revisions_during_month(courses, month, year)
    article_count(revisions)
  end

  def monthly_uploads_for(courses, month, year)
    student_ids = student_ids_for(courses)
    uploads = CommonsUpload
              .where(user_id: student_ids)
              .where('extract(month from uploaded_at) = ?', month)
              .where('extract(year from uploaded_at) = ?', year)
    uploads.count
  end

  def revision_ids_for(courses)
    revision_ids = []
    courses.each do |course|
      revision_ids += course.revisions.pluck(:id)
    end
    revision_ids.uniq
  end

  def revisions_during_month(courses, month, year)
    all_course_revision_ids = revision_ids_for(courses)
    revisions = Revision
                .where(id: all_course_revision_ids)
                .where('extract(month from date) = ?', month)
                .where('extract(year from date) = ?', year)
    revisions
  end

  def article_count(revisions)
    article_ids = revisions.pluck(:article_id)
    articles = Article.where(id: article_ids, namespace: 0, deleted: false)
    articles.distinct.count
  end

  def student_ids_for(courses)
    student_ids = courses.map { |course| course.students.pluck(:id) }
    student_ids.flatten.uniq
  end
end
