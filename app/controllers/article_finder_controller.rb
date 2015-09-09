require "#{Rails.root}/lib/importers/category_importer"

#= Controller for Article Finder tool
class ArticleFinderController < ApplicationController
  def index
    @articles = []
    return unless params[:category]
    @category = params[:category]
    @depth = params[:depth].to_i
    @min_views = params[:minviews].to_i
    @max_wp10 = params[:maxwp10].to_i
    @articles = CategoryImporter.show_category(@category, depth: @depth,
                                                          min_views: @min_views,
                                                          max_wp10: @max_wp10)
  end
end
