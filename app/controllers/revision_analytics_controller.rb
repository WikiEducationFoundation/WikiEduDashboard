# frozen_string_literal: true

# Controller for Revision Analytics features
class RevisionAnalyticsController < ApplicationController
  respond_to :json

  def recent_uploads
    student_ids = User.role('student').pluck(:id)
    @uploads = CommonsUpload.where(user_id: student_ids).order(id: :desc).first(100)
  end
end
