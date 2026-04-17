# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/revision_feedback_service"
require_dependency "#{Rails.root}/lib/lift_wing_api"
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

class RevisionFeedbackController < ApplicationController
  def index
    set_latest_revision_id
    return if @rev_id.nil?
    revision_data = LiftWingApi.new(@wiki).get_revision_data([@rev_id])[@rev_id.to_s]
    @feedback = RevisionFeedbackService.new(revision_data['features']).feedback
    @user_feedback = Assignment.find(params['assignment_id']).assignment_suggestions
    @rating = revision_data['prediction']
  end

  private

  def set_latest_revision_id
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    @rev_id = WikiApi::ArticleContent.new(@wiki).latest_revision_id(params['title'])
  end
end
