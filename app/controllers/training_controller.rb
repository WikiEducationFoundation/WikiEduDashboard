class TrainingController < ApplicationController

  def index
    @libs = TrainingLibrary.all
  end

  def show
    @library = params[:library_id]
    @modules = TrainingLibrary.find_library(library: @library)
  end

  def training_module
    library = params[:library_id]
    t_module = params[:module_id]
    @training_module = TrainingLibrary.find_module(library: library, module: t_module)
  end

end
