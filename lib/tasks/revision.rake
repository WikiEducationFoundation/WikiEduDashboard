namespace :revision do

  desc 'Update the data for current-term revisions (and articles...)'

  task :update_revisions => :environment do
    Rails.logger.info "Updating all revisions"
    Revision.update_all_revisions
  end

end