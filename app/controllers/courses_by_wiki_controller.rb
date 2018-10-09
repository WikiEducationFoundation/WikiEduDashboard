# frozen_string_literal: true

class CoursesByWikiController < ApplicationController
  respond_to :html

  before_action :set_wiki

  def show
    @courses_list = Course.where(home_wiki: @wiki).order(id: :desc)
    @presenter = CoursesPresenter.new(current_user: current_user, courses_list: @courses_list)
  end

  private

  def set_wiki
    @wiki = Wiki.get_or_create(language: params[:language], project: params[:project])
  end
end
