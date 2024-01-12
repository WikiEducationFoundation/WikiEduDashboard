# frozen_string_literal: true

require_dependency Rails.root.join('lib/article_utils')

class CategoriesController < ApplicationController
  respond_to :json
  before_action :set_course_and_validate

  def add_categories
    source = params[:source]
    categories_params = params[:categories]
    categories_params[:items].each do |category|
      update_wiki category[:value][:wiki]
      depth = category[:value][:depth] || 0
      add_category(depth:, name: category[:value][:title], source:)
    end
    render 'courses/categories'
  rescue ActiveRecord::RecordNotUnique
    render 'courses/categories'
  end

  def remove_category
    @category = Category.find(params[:category_id])
    CategoriesCourses.find_by(course: @course, category: @category).destroy
    render 'courses/categories'
  end

  def category
    @category = Category.find(params[:id])
    render 'categories/category'
  end

  private

  def set_course_and_validate
    @course = Course.find(params[:course_id])
    raise NotPermittedError unless current_user&.can_edit?(@course)
  end

  def update_wiki(wiki)
    wiki_language = wiki[:language]
    wiki_project = wiki[:project]
    return if @wiki && @wiki.language == wiki_language && @wiki.project == wiki_project
    @wiki = Wiki.get_or_create(language: wiki_language, project: wiki_project)
  end

  def add_category(params)
    name = ArticleUtils.format_article_title(params[:name])
    @category = Category.find_or_create_by(wiki: @wiki, depth: params[:depth],
                                           name:, source: params[:source])
    @course.categories << @category
  end
end
