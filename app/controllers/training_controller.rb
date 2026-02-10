# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training_progress_manager"
require_dependency "#{Rails.root}/lib/data_cycle/training_update"
require_dependency "#{Rails.root}/lib/training/training_resource_query_object"

class TrainingController < ApplicationController
  layout 'training'
  before_action :init_query_object, only: :index
  before_action :fetch_current_training_mode, only: [:index, :show, :training_module, :slide_view]

  def index
    if @search
      @slides = @query_object.selected_slides_and_excerpt
    else
      @focused_library_slug, @libraries = @query_object.all_libraries

      render 'no_training_module' if @libraries.empty?
    end
  end

  def show
    add_training_root_breadcrumb
    add_library_breadcrumb
    fail_if_entity_not_found(TrainingLibrary, params[:library_id])
    @library = TrainingLibrary.find_by(slug: params[:library_id])
  end

  def training_module
    fail_if_entity_not_found(TrainingModule, params[:module_id])
    # Save the return-to source, typically a course page, so that
    # at the end of the training we can return the user to where they
    # started from.
    session[:training_return_to] = request.referer
    @pres = TrainingModulePresenter.new(current_user, params)
    add_training_root_breadcrumb
    add_library_breadcrumb
    add_module_breadcrumb(@pres.training_module)
  end

  def slide_view
    training_module = TrainingModule.find_by(slug: params[:module_id])
    raise ActionController::RoutingError, 'not found' if training_module.nil?
    if current_user
      @tmu = TrainingModulesUsers.find_or_create_by(
        user_id: current_user.id,
        training_module_id: training_module.id
      )
      @training_module_name = training_module.name
    end
    add_training_root_breadcrumb
    add_module_breadcrumb(training_module)
  end

  def reload
    render plain: TrainingUpdate.new(module_slug: params[:module]).result
  rescue TrainingBase::DuplicateSlugError,
         TrainingModule::ModuleNotFound, WikiTrainingLoader::NoMatchingWikiPagesFound,
         YamlTrainingLoader::InvalidYamlError => e
    render plain: e.message
  end

  def find_slide
    training_slide = TrainingSlide.find(params[:slide_id])
    training_module = training_slide.find_module_by_slug
    raise ActionController::RoutingError, 'module not found' unless training_module
    # Use a specific training library for the module, or a default library if it is not found
    training_library = training_module.find_or_default_library
    redirect_to "/training/#{training_library.slug}/#{training_module.slug}/#{training_slide.slug}"
  end

  def update_training_mode
    edit_mode_value = params[:edit_mode]
    store_training_mode_in_session(edit_mode_value)
    render json: { message: 'Training Mode Updated Successfully.' }, status: :ok
  end

  private

  def fetch_current_training_mode
    @current_training_mode = session[:training_mode] || { 'editMode' => false }
  end

  def store_training_mode_in_session(edit_mode_value)
    session[:training_mode] = { 'editMode' => ActiveModel::Type::Boolean.new.cast(edit_mode_value) }
  end

  def add_training_root_breadcrumb
    add_breadcrumb I18n.t('training.training_library'), :training_path
  end

  def add_library_breadcrumb
    lib_id = params[:library_id]
    if Features.wiki_ed?
      add_breadcrumb lib_id.titleize, :training_library_path
    else
      add_breadcrumb(
        TrainingLibrary.find_by(slug: lib_id)&.translated_name || lib_id.titleize,
        :training_library_path
      )
    end
  end

  def add_module_breadcrumb(training_module)
    add_breadcrumb training_module.translated_name, :training_module_path
  end

  def fail_if_entity_not_found(entity, finder)
    return if entity.find_by(slug: finder).present?
    raise ActionController::RoutingError, 'not found'
  end

  def init_query_object
    @search = params[:search_training]
    @query_object = TrainingResourceQueryObject.new(current_user, @search)
  end
end
