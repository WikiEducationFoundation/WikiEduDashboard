# frozen_string_literal: true

class CoursesByWikiController < ApplicationController
  respond_to :html, :json

  before_action :set_wiki

  def show
    respond_to do |format|
      format.html { render }
      format.json do
        courses_list = Course.where(home_wiki: @wiki).order(id: :desc)
        # rubocop:disable Layout/LineLength
        courses_list = courses_list.where("year(created_at) = #{params[:year].to_i}") if params[:year]
        # rubocop:enable Layout/LineLength
        @presenter = CoursesPresenter.new(current_user: current_user, courses_list: courses_list)
      end
    end
  end

  private

  def set_wiki
    @wiki = Wiki.get_or_create(language: params[:language], project: params[:project])
  end
end
