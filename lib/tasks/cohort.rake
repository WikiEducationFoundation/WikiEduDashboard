namespace :cohort do
  desc 'Add new cohorts from application.yml'
  task add_cohorts: :environment do
    Rails.logger.debug 'Adding new cohorts (if there are any to add)'
    Cohort.initialize_cohorts
  end
end
