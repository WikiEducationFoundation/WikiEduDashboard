require "#{Rails.root}/lib/importers/category_importer"

#= Controller for Article Finder tool
class ArticleFinderController < ApplicationController
  DEFAULT_MAX_WP10_SCORE = 100

  def index
  end

  def results
    @articles = []
    return unless params[:category]
    @category = params[:category]
    cat_name = 'Category:' + @category
    @depth = params[:depth].to_i
    @min_views = params[:minviews].to_i
    @max_wp10 = (params[:maxwp10] || DEFAULT_MAX_WP10_SCORE).to_i
    @articles = CategoryImporter.show_category(cat_name, depth: @depth,
                                                         min_views: @min_views,
                                                         max_wp10: @max_wp10)
    render 'index'
  end
end
