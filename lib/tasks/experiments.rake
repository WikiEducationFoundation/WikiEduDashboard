# frozen_string_literal: true

require Rails.root.join('lib/experiments/fall2017_cmu_experiment')
require Rails.root.join('lib/experiments/spring2018_cmu_experiment')

namespace :experiments do
  desc 'Process Fall 2017 courses for CMU experiment'
  task fall_2017_cmu_experiment: :environment do
    Rails.logger.debug 'Enrolling new Fall 2017 courses in CMU experiment'
    Fall2017CmuExperiment.process_courses
  end

  desc 'Process Spring 2018 courses for CMU experiment'
  task spring_2018_cmu_experiment: :environment do
    Rails.logger.debug 'Enrolling new Spring 2018 courses in CMU experiment'
    Spring2018CmuExperiment.process_courses
  end
end
