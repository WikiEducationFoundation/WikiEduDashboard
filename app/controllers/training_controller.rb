class TrainingController < ApplicationController

  def index
    @libs = TrainingLibrary.all
  end

  def show
    @training_content = TrainingLibrary.find(library: params[:library_id])
    render 'index'
  end

end
