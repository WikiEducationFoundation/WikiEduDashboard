# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/revision_analytics_service"

# Controller for Revision Analytics features
class RevisionAnalyticsController < ApplicationController
  respond_to :json

  def dyk_eligible
    @articles = RevisionAnalyticsService.dyk_eligible(
      scoped: params[:scoped],
      current_user:
    )
  end

  def recent_uploads
    student_ids = User.role('student').pluck(:id)
    @uploads = CommonsUpload.where(user_id: student_ids).order(id: :desc).first(100)
  end
end
