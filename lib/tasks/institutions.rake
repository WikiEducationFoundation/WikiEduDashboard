# frozen_string_literal: true

namespace :institutions do
  desc 'Creates Institution records from existing Course#school values and links courses to them'
  task migrate: :environment do
    Course.distinct.pluck(:school).compact_blank.each do |school|
      institution = Institution.find_or_create_by!(name: school)
      # update_all skips Course validations and callbacks on purpose:
      # this is a pure data link, and those callbacks can silently block or alter rows.
      Course.where(school:).update_all(institution_id: institution.id) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
