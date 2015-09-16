require "#{Rails.root}/lib/analytics/monthly_report"
require "#{Rails.root}/lib/analytics/course_statistics"

#= Controller for analytics tools
class AnalyticsController < ApplicationController
  def index
  end

  def results
    if params[:monthly_report]
      @monthly_report = MonthlyReport.run
    elsif params[:cohort_stats]
      @cohort_stats = {}
      Cohort.all.each do |cohort|
        ids = cohort.courses.pluck(:id)
        stats = CourseStatistics.report_statistics(ids, cohort: cohort.slug)
        @cohort_stats.merge! stats
      end
    end
    render 'index'
  end
end
