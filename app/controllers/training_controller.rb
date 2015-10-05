class TrainingController < ApplicationController
  add_breadcrumb 'Training Library', :training_path

  def index
    @libraries = TrainingLibrary.all
  end

  def show
    add_breadcrumb params[:library_id].titleize
    @library = TrainingLibrary.find_by(slug: params[:library_id])
  end

  def training_module
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end

end
