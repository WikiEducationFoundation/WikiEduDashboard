# frozen_string_literal: true
namespace :institutions do
  desc 'Creates Institution records from existing Course#school values and links courses to them'
  task migrate: :environment do
    Course.find_each do |course|
      next if course.school.blank?

      institution = Institution.find_or_create_by(name: course.school)
      course.update(institution: institution)
    end
  end
end
