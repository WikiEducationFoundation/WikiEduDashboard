require "#{Rails.root}/lib/revision_feedback_service"
require "#{Rails.root}/lib/importers/revision_score_importer"

class RevisionFeedbackController < ApplicationController
  def index
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    @revision = Revision.find_by(mw_rev_id: params[:rev_id], wiki_id: @wiki.id)
    set_new_revision unless @revision
    @feedback = RevisionFeedbackService.new(@revision).feedback
  end

  private

  def set_new_revision
    @revision = Revision.new(wiki_id: @wiki.id, mw_rev_id: params[:rev_id], mw_page_id: 0)
    @revision.save!
    RevisionScoreImporter.new.update_revision_scores([@revision])
    @revision.reload
  end
end
