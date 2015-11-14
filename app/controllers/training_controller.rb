class TrainingController < ApplicationController
  layout 'training'
  add_breadcrumb 'Training Library', :training_path, only: :slide_view

  def index
    @libraries = TrainingLibrary.all
  end

  def show
    add_breadcrumb 'Training Library', :training_path
    add_breadcrumb params[:library_id].titleize, :training_library_path
    fail_if_entity_not_found(TrainingLibrary, params[:library_id])
    @library = TrainingLibrary.find_by(slug: params[:library_id])
  end

  def training_module
    add_breadcrumb 'Training Library', :training_path
    add_breadcrumb params[:library_id].titleize, :training_library_path
    add_breadcrumb params[:module_id].titleize, :training_module_path
    fail_if_entity_not_found(TrainingModule, params[:module_id])
    @pres = TrainingModulePresenter.new(current_user, params)
  end

  def slide_view
    if current_user
      @tmu = TrainingModulesUsers.find_or_create_by(
        user_id: current_user.id,
        training_module_id: TrainingModule.find_by(slug: params[:module_id]).id
      )
    end
    add_breadcrumb params[:module_id].titleize, :training_module_path
  end

  private

  def fail_if_entity_not_found(entity, finder)
    fail ActiveRecord::RecordNotFound unless entity.find_by(slug: finder).present?
  end
end
