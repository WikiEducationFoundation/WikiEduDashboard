# frozen_string_literal: true

#= Admin-only access to the real title and institution of a privacy-mode
#= course. Everywhere else in the application, a privacy-mode course is
#= represented by the obfuscated values stored on the course itself; this is the
#= only surface that reads or writes the real ones.
class ConfidentialCourseDetailsController < ApplicationController
  respond_to :json
  before_action :require_admin_permissions
  before_action :set_detail

  def show
    return render json: { confidential_course_detail: nil } if @detail.nil?
    render json: { confidential_course_detail: detail_json }
  end

  def update
    return render_not_in_privacy_mode if @detail.nil?
    if @detail.update(detail_params)
      render json: { confidential_course_detail: detail_json }
    else
      render json: { errors: @detail.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def render_not_in_privacy_mode
    render json: { error: 'Course is not in privacy mode' }, status: :not_found
  end

  def set_detail
    @detail = ConfidentialCourseDetail.find_by(course_id: params[:course_id])
  end

  def detail_json
    @detail.slice(:id, :course_id, :sequence, :real_title, :real_school)
  end

  # `sequence` is deliberately not writable: the course slug and its on-wiki
  # page are built from it and are already published.
  def detail_params
    params.require(:confidential_course_detail).permit(:real_title, :real_school)
  end
end
