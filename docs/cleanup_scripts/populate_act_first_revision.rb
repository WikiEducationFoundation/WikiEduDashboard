# frozen_string_literal: true
# This script populates first_revision article course timeslice field

require_dependency "#{Rails.root}/app/models/article_course_timeslice"

ArticleCourseTimeslice.where.not(revision_count: 0).in_batches do |act_batch|
  # rubocop:disable Rails/SkipsModelValidations
  act_batch.update_all('first_revision = start')
  # rubocop:enable Rails/SkipsModelValidations
end
