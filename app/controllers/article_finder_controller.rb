require "#{Rails.root}/lib/importers/category_importer"

class ArticleFinderController < ApplicationController
  def index
    if params[:q]
      @category = params[:q]
      @output = CategoryImporter.report_on_category(@category)
    end
  end
end
