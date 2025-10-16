# frozen_string_literal: true

#= Utilities for calcuating statistics by month, and year-over-year
class MonthlyReport
  def self.run(opts = {})
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
    timeslices = article_course_timeslices_during_month(courses, month, year)
    article_count(timeslices)
  end

  def monthly_uploads_for(courses, month, year)
    student_ids = student_ids_for(courses)
    uploads = CommonsUpload
              .where(user_id: student_ids)
              .where('extract(month from uploaded_at) = ?', month)
              .where('extract(year from uploaded_at) = ?', year)
    uploads.count
  end

  def act_ids_for(courses)
    act_ids = []
    courses.each do |course|
      act_ids += course.tracked_article_course_timeslices.pluck(:id)
    end
    act_ids
  end

  def article_course_timeslices_during_month(courses, month, year)
    all_act_ids = act_ids_for(courses)
    ArticleCourseTimeslice
      .where(id: all_act_ids)
      .where('extract(month from start) = ?', month)
      .where('extract(year from start) = ?', year)
  end

  def article_count(timeslices)
    article_ids = timeslices.pluck(:article_id)
    articles = Article.where(id: article_ids, namespace: 0, deleted: false)
    articles.distinct.count
  end

  def student_ids_for(courses)
    student_ids = courses.map { |course| course.students.pluck(:id) }
    student_ids.flatten.uniq
  end
end
