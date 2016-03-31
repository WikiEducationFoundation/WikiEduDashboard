require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/lib/importers/revision_score_importer"
require "#{Rails.root}/lib/importers/plagiabot_importer"

namespace :revision do
  desc 'Update the data for current-term revisions and articles'
  task update_revisions: 'batch:setup_logger' do
    Rails.logger.debug 'Updating all revisions'
    RevisionImporter.update_all_revisions
  end

  desc 'Import wp10 scores for all en.wiki revisions'
  task update_revision_scores: 'batch:setup_logger' do
    Rails.logger.debug 'Importing wp10 scores for all en.wiki revisions'
    RevisionScoreImporter.new.update_revision_scores
  end

  desc 'Update deleted status for all revisions'
  task update_deleted_revisions: 'batch:setup_logger' do
    Rails.logger.debug 'Updating deleted status of all revisions'
    RevisionImporter.new.move_or_delete_revisions
  end

  desc 'Import recent plagiabot data for revisions'
  task import_recent_plagiarism: 'batch:setup_logger' do
    Rails.logger.debug 'Updating deleted status of all revisions'
    PlagiabotImporter.find_recent_plagiarism
  end
end
