require "#{Rails.root}/lib/analytics/course_statistics"
require "#{Rails.root}/lib/analytics/monthly_report"

namespace :analytics do
  desc 'Report on the productivity of students, per cohort'
  task stats_per_cohort: 'batch:setup_logger' do
    Cohort.all.each do |cohort|
      course_ids = cohort.courses.where(listed: true).pluck(:id)
      report = CourseStatistics.report_statistics course_ids
      report = "#{cohort.slug}:" + report
      Rails.logger.info report
    end
  end

  desc 'Report on the productivity of all students'
  task combined_stats: 'batch:setup_logger' do
    course_ids = []
    Cohort.all.each do |cohort|
      course_ids += cohort.courses.where(listed: true).pluck(:id)
    end
    report = CourseStatistics.report_statistics course_ids
    Rails.logger.info report
  end

  desc 'Monthly report for year-over-year statistics'
  task monthly_report: 'batch:setup_logger' do
    report = MonthlyReport.run
    Rails.logger.info report
  end

  desc 'Report on estimated article quality'
  task ores: 'batch:setup_logger' do
    Analytics.article_quality(Course.all)
  end
end
