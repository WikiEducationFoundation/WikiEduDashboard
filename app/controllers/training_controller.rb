class TrainingController < ApplicationController
  layout 'training'
  add_breadcrumb 'Training Library', :training_path

  def index
    @libraries = TrainingLibrary.all
  end

  def show
    add_breadcrumb params[:library_id].titleize, :training_library_path
    @library = TrainingLibrary.find_by(slug: params[:library_id])
  end

  def training_module
    add_breadcrumb params[:library_id].titleize, :training_library_path
    add_breadcrumb params[:module_id].titleize
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end

end
