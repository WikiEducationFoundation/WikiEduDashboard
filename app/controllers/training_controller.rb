class TrainingController < ApplicationController

  def index
    @libraries = TrainingLibrary.all
  end

  def show
    @library = TrainingLibrary.find_by(slug: params[:library_id])
  end

  def training_module
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end

end
