# frozen_string_literal: true

require "#{Rails.root}/setup/populate_dashboard"

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
end
