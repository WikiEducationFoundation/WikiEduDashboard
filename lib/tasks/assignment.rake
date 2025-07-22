# frozen_string_literal: true

def generate_generic_sandbox_url(assignment)
  # If there's already a sandbox_url, do nothing
  return false if assignment.sandbox_url

  wiki = assignment.wiki
  user = assignment.user

  # If the assignment doesn't have a user or wiki, do nothing
  return false unless wiki && user

  language = wiki.language || 'en'
  base_url = "https://#{language}.#{wiki.project}.org/wiki"
  "#{base_url}/User:#{user.username}/sandbox"
end

namespace :assignment do
  # This task will assign sandbox_urls to all valid assignments
  # that were created before August 2019
  desc 'Give assignments default sandbox_url'
  task set_sandbox_url: :environment do
    Rails.logger.debug 'Setting sandbox_url for all assignments'
    Assignment.where('created_at < ?', '2019-08-01'.to_date).find_each do |assignment|
      url = generate_generic_sandbox_url(assignment)
      # update_columns will skip the callbacks on assignment
      # rubocop:disable Rails/SkipsModelValidations
      assignment.update_columns(sandbox_url: url) if url
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
