# frozen_string_literal: true

# Controller for Revision Analytics features
class RevisionAnalyticsController < ApplicationController
  respond_to :json

  # Public, so students of private courses are left out.
  def recent_uploads
    student_ids = CoursesUsers.where(role: CoursesUsers::Roles::STUDENT_ROLE,
                                     course: Course.nonprivate).select(:user_id)
    @uploads = CommonsUpload.where(user_id: student_ids).order(id: :desc).first(100)
  end
end
