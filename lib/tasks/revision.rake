require "#{Rails.root}/lib/importers/revision_importer"

namespace :revision do
  desc 'Update the data for current-term revisions and articles'
  task update_revisions: "batch:setup_logger" do
    Rails.logger.debug 'Updating all revisions'
    RevisionImporter.update_all_revisions
  end
end
