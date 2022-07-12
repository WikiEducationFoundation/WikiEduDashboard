# frozen_string_literal: true

class CoursesByWikiController < ApplicationController
  respond_to :html, :json

  before_action :set_wiki

  def show
    @courses_list = Course.where(home_wiki: @wiki).order(id: :desc)
    @courses_list = @courses_list.where("year(created_at) = #{params[:year].to_i}") if params[:year]
    @presenter = CoursesPresenter.new(current_user: current_user, courses_list: @courses_list)
    @courses = @presenter.courses
  end

  private

  def set_wiki
    @wiki = Wiki.get_or_create(language: params[:language], project: params[:project])
  end
end
