# frozen_string_literal: true
require "#{Rails.root}/lib/revision_feedback_service"
require "#{Rails.root}/lib/importers/revision_score_importer"

class RevisionFeedbackController < ApplicationController
  before_action :initialize_ores

  def index
    set_revision_id
    unless @revId.nil?
      features = ores_features(@revId)
      @feedback = RevisionFeedbackService.new(features).feedback
    end
  end

  private

  def initialize_ores
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    @ores_api = OresApi.new(@wiki)
  end

    def ores_features(revId)
    ores_data = @ores_api.get_revision_data(revId)
    score = extract_score ores_data
    return extract_features(ores_data)[revId.to_s]
  end

  def set_revision_id
    @article = Article.find(params[:article_id])

    query = { prop: 'revisions', pageids: @article.mw_page_id, rvprop: 'ids' }
    response = WikiApi.new(@wiki).query(query)
    results = response&.data
    revisions = results.dig('pages', @article.mw_page_id.to_s, 'revisions')

    # The API sends a response with the id of the last revision
    unless revisions.nil? || revisions.length == 0
      @revId = revisions[0]['revid']
    end
    @revId
  end

  def extract_score(ores_data)
    return ores_data if ores_data.blank?
    scores = ores_data.dig('scores', 'enwiki', 'wp10', 'scores')
    scores || {}
  end

  def extract_features(ores_data)
    return ores_data if ores_data.blank?
    features = ores_data.dig('scores', 'enwiki', 'wp10', 'features')
    features || {}
  end

end
