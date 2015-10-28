class TrainingController < ApplicationController
  layout 'training'
  add_breadcrumb 'Training Library', :training_path, only: :slide_view

  def index
    @libraries = TrainingLibrary.all
  end

  def show
    @library = TrainingLibrary.find_by(slug: params[:library_id])
  end

  def training_module
    @library = TrainingLibrary.find_by(slug: params[:library_id])
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end

  def slide_view
    @tmu = TrainingModulesUsers.find_or_create_by(
      user_id: current_user.id,
      training_module_id: TrainingModule.find_by(slug: params[:module_id]).id
    )
    add_breadcrumb params[:module_id].titleize, :training_module_path
  end

end
