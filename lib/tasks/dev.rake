# frozen_string_literal: true

require "#{Rails.root}/setup/populate_dashboard"
require "#{Rails.root}/setup/populate_surveys"

namespace :dev do
  desc 'Set up some example data'
  task populate: :environment do
    populate_dashboard
  end

  desc 'Copy a course from production'
  task copy_course: :environment do
    ARGV.each { |a| task(a.to_sym) {} }

    course_url = ARGV[1]
    make_copy_of course_url
  end
  desc 'Populate Survey Questions'
  task populate_surveys: :environment do
    populate_survey_questions
    populate_survey_answers
  end
end
