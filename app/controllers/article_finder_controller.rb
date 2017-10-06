# frozen_string_literal: true

require "#{Rails.root}/lib/importers/category_importer"

#= Controller for Article Finder tool
class ArticleFinderController < ApplicationController
  DEFAULT_MAX_WP10_SCORE = 100
  MAX_DEPTH = 2

  def index
    @depth ||= 0
    @min_views ||= 0
    @max_wp10 ||= DEFAULT_MAX_WP10_SCORE
    @title ||= 'Article Finder'
  end

  def results
    @articles = []
    return unless params[:category]
    @wiki = Wiki.default_wiki
    set_query_params
    @articles = CategoryImporter
                .new(@wiki, depth: @depth, min_views: @min_views, max_wp10: @max_wp10)
                .show_category(@cat_name)
    render 'index'
  end

  private

  def set_query_params
    @category = params[:category]
    @title = "Category: #{@category}"
    @cat_name = 'Category:' + @category
    @depth = [params[:depth].to_i, 2].min
    @min_views = params[:minviews].to_i
    @max_wp10 = params[:maxwp10].to_i
  end
end
