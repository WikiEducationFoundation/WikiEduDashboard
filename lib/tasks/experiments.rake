# frozen_string_literal: true

require "#{Rails.root}/lib/experiments/fall2017_cmu_experiment"

namespace :experiments do
  desc 'Process Fall 2017 courses for CMU experiment'
  task fall_2017_cmu_experiment: :environment do
    Rails.logger.debug 'Enrolling new Fall 2017 courses in CMU experiment'
    Fall2017CmuExperiment.process_courses
  end
end
