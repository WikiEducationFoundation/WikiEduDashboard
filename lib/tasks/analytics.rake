require "#{Rails.root}/lib/analytics"

namespace :analytics do
  desc 'Report on the productivity of students, per cohort'
  task stats_per_cohort: 'batch:setup_logger' do
    Cohort.all.each do |cohort|
      course_ids = cohort.courses.where(listed: true).pluck(:id)
      report = Analytics.report_statistics course_ids
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
    report = Analytics.report_statistics course_ids
    Rails.logger.info report
  end
end
