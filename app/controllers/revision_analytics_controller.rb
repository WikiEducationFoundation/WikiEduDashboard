# frozen_string_literal: true

require "#{Rails.root}/lib/revision_analytics_service"

# Controller for Revision Analytics features
class RevisionAnalyticsController < ApplicationController
  respond_to :json

  def dyk_eligible
    @articles = RevisionAnalyticsService.dyk_eligible(
      scoped: params[:scoped],
      current_user: current_user
    )
  end

  def suspected_plagiarism
    @revisions = RevisionAnalyticsService.suspected_plagiarism(
      scoped: params[:scoped],
      current_user: current_user
    )
  end

  def recent_edits
    @revisions = RevisionAnalyticsService.recent_edits(
      scoped: params[:scoped],
      current_user: current_user
    )
  end

  def recent_uploads
    student_ids = User.role('student').pluck(:id)
    @uploads = CommonsUpload.where(user_id: student_ids).order(id: :desc).first(100)
  end
end
