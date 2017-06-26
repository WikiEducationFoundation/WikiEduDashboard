# frozen_string_literal: true
require "#{Rails.root}/lib/revision_feedback_service"
require "#{Rails.root}/lib/importers/revision_score_importer"

class RevisionFeedbackController < ApplicationController

  def index
    set_latest_revision_id
    unless @rev_id.nil?
      ores_data = RevisionScoreImporter.new.fetch_ores_data_for_revision_id(@rev_id)
      @feedback = RevisionFeedbackService.new(ores_data[:features]).feedback
      @rating = ores_data[:rating]
    end
  end

  private

  def set_latest_revision_id
    @article = Article.find(params[:article_id])

    query = { prop: 'revisions', pageids: @article.mw_page_id, rvprop: 'ids' }
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    response = WikiApi.new(@wiki).query(query)
    results = response&.data
    revisions = results.dig('pages', @article.mw_page_id.to_s, 'revisions')

    # The API sends a response with the id of the last revision
    unless revisions.nil? || revisions.length == 0
      @rev_id = revisions[0]['revid']
    end
  end

end
