require "#{Rails.root}/lib/importers/category_importer"

#= Controller for Article Finder tool
class ArticleFinderController < ApplicationController
  def index
    @articles = []
    return unless params[:category]
    @category = params[:category]
    @depth = params[:depth].to_i
    @articles = CategoryImporter.show_category(@category, depth: @depth)
  end
end
