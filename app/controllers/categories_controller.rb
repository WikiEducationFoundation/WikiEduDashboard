# frozen_string_literal: true

require "#{Rails.root}/lib/article_utils"

class CategoriesController < ApplicationController
  respond_to :json
  before_action :require_permissions, :set_course

  def add_category
    set_wiki
    name = ArticleUtils.format_article_title(params[:category_name])
    @category = Category.find_or_create_by(wiki: @wiki, depth: params[:depth],
                                           name: name, source: params[:source])
    @course.categories << @category
    render 'courses/categories'
  rescue ActiveRecord::RecordNotUnique
    render 'courses/categories'
  end

  def remove_category
    @category = Category.find(params[:category_id])
    CategoriesCourses.find_by(course: @course, category: @category).destroy
    render 'courses/categories'
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_wiki
    @wiki = Wiki.get_or_create(language: params[:language], project: params[:project])
  end
end
