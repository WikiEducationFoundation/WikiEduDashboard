require "#{Rails.root}/lib/analytics/monthly_report"
require "#{Rails.root}/lib/analytics/course_statistics"

#= Controller for analytics tools
class AnalyticsController < ApplicationController
  ########################
  # Routing entry points #
  ########################
  def index
  end

  def results
    if params[:monthly_report]
      monthly_report
    elsif params[:cohort_stats]
      cohort_stats
    elsif params[:cohort_intersection]
      cohort_intersection
    end
    render 'index'
  end

  ###################
  # Output builders #
  ###################

  def monthly_report
    @monthly_report = MonthlyReport.run
  end

  def cohort_stats
    @cohort_stats = {}
    Cohort.all.each do |cohort|
      course_ids = cohort.courses.pluck(:id)
      stats =
        CourseStatistics.report_statistics(course_ids, cohort: cohort.slug)
      @cohort_stats.merge! stats
    end
  end

  def cohort_intersection
    @cohort_stats = {}
    @cohort_1 = Cohort.find(params[:cohort_1][:id])
    @cohort_2 = Cohort.find(params[:cohort_2][:id])

    cohort_name = @cohort_1.title + ' + ' + @cohort_2.title
    cohort_1_course_ids = @cohort_1.courses.pluck(:id)
    course_ids = @cohort_2.courses
                 .where(id: cohort_1_course_ids)
                 .pluck(:id)
    stats =
      CourseStatistics.report_statistics(course_ids, cohort: cohort_name)
    @cohort_stats.merge! stats
    @articles_edited = CourseStatistics.articles_edited(course_ids)
  end
end
