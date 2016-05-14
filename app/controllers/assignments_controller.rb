require 'uri'

# Controller for Assignments
class AssignmentsController < ApplicationController
  respond_to :json

  def index
    set_course
    @assignments = Assignment.where(user_id: params[:user_id],
                                    role: params[:role],
                                    course_id: @course.id)
    render json: @assignments
  end

  def destroy
    id = params[:id]
    Assignment.find(id).destroy
    render json: { article: id }
  end

  def create
    set_course
    set_wiki
    @assignment = Assignment.create(user_id: assignment_params[:user_id],
                                    course_id: @course.id,
                                    wiki_id: @wiki.id,
                                    article_title: assignment_params[:article_title],
                                    role: assignment_params[:role])
    render json: @assignment
  end

  private

  def set_course
    @course = Course.find_by_slug(URI.unescape(params[:course_id]))
  end

  def set_wiki
    home_wiki = @course.home_wiki
    language = params[:language] || home_wiki.language
    project = params[:project] || home_wiki.project
    @wiki = Wiki.find_by(language: language, project: project)
    @wiki_id ||= home_wiki.id
  end

  def assignment_params
    params.permit(:user_id, :course_id, :article_title, :role, :language, :project)
  end
end
