namespace :cohort do
  desc 'Add new cohorts from application.yml'
  task add_cohorts: 'batch:setup_logger' do
    Rails.logger.debug 'Adding new cohorts (if there are any to add)'
    Cohort.initialize_cohorts
  end
end
