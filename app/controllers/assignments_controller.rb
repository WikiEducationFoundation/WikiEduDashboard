require 'uri'

class AssignmentsController < ApplicationController
  respond_to :json

  def index
    course = Course.find_by_slug(URI.unescape(params[:course_id]))
    @assignments = Assignment.where(user_id: params[:user_id], role: params[:role], course_id: course.id)
    render json: @assignments
  end

  def destroy
    id = params[:id]
    Assignment.find(id).destroy
    render json: { article: id }
  end

  def create
    course = Course.find_by_slug(URI.unescape(params[:course_id]))
    params.delete(:course_id)
    params.merge!(course_id: course.id)
    @assignment = Assignment.create(assignment_params)
    render json: @assignment
  end

  private

  def assignment_params
    params.permit(:user_id, :course_id, :article_title, :role)
  end


end
