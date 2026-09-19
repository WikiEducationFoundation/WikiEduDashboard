# frozen_string_literal: true

namespace :retention_stats do
  desc 'Compute and store retention stats for the Scholars & Scientists courses in one campaign'
  task :backfill, [:campaign_slug] => :environment do |_task, args|
    abort 'Usage: rake retention_stats:backfill[campaign_slug]' if args[:campaign_slug].blank?
    campaign = Campaign.find_by(slug: args[:campaign_slug])
    abort "No campaign with slug #{args[:campaign_slug]}" unless campaign

    courses = campaign.courses.where(type: 'FellowsCohort').order(:start)
    puts "#{courses.count} Scholars & Scientists courses in #{campaign.slug}"
    courses.each do |course|
      unless RetentionStat.update_due?(course)
        puts "  skip  #{course.slug} (already current)"
        next
      end
      begin
        UpdateCourseRetentionStats.new(course)
        puts "  done  #{course.slug} (#{course.retention_stats.count} students)"
      rescue RetentionFetchError => e
        puts "  FAIL  #{course.slug}: #{e.message} (rerun the task to retry)"
      end
    end
  end
end
