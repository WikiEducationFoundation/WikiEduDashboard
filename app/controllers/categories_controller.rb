# frozen_string_literal: true

class CategoriesController < ApplicationController
  respond_to :json
  before_action :require_signed_in
  # TODO: check permissions

  def add_category
    # TODO: find or create category
    # TODO: add to course
    render 'courses/categories'
  end

  def remove_category
    @course = Course.find(params[:course_id])
    @category = Category.find(params[:category_id])
    CategoriesCourses.find_by(course: @course, category: @category).destroy
    render 'courses/categories'
  end
end
