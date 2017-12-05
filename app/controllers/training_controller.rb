# frozen_string_literal: true

require "#{Rails.root}/lib/training_progress_manager"
require "#{Rails.root}/lib/training_library"
require "#{Rails.root}/lib/training_module"

class TrainingController < ApplicationController
  layout 'training'

  def index
    @libraries = TrainingLibrary.all.sort_by(&:name)
  end

  def show
    add_training_root_breadcrumb
    add_library_breadcrumb
    fail_if_entity_not_found(TrainingLibrary, params[:library_id])
    @library = TrainingLibrary.find_by(slug: params[:library_id])
  end

  def training_module
    fail_if_entity_not_found(TrainingModule, params[:module_id])
    @pres = TrainingModulePresenter.new(current_user, params)
    add_training_root_breadcrumb
    add_library_breadcrumb
    add_module_breadcrumb(@pres.training_module)
  end

  def slide_view
    training_module = TrainingModule.find_by(slug: params[:module_id])
    if current_user
      @tmu = TrainingModulesUsers.find_or_create_by(
        user_id: current_user.id,
        training_module_id: training_module.id
      )
    end
    add_training_root_breadcrumb
    add_module_breadcrumb(training_module)
  end

  def reload
    if params[:module] == 'all'
      TrainingModule.load_all
    else
      reload_single_module
    end
    render plain: 'done!'
  rescue TrainingBase::DuplicateIdError, TrainingBase::DuplicateSlugError,
         TrainingModule::ModuleNotFound, TrainingLoader::NoMatchingWikiPagesFound => e
    render plain: e.message
  end

  private

  def reload_single_module
    TrainingModule.reload_module(slug: params[:module])
  end

  def add_training_root_breadcrumb
    add_breadcrumb 'Training Library', :training_path
  end

  def add_library_breadcrumb
    add_breadcrumb params[:library_id].titleize, :training_library_path
  end

  def add_module_breadcrumb(training_module)
    add_breadcrumb training_module.name, :training_module_path
  end

  def fail_if_entity_not_found(entity, finder)
    raise ModuleNotFound, "#{entity}: #{finder}" unless entity.find_by(slug: finder).present?
  end

  class ModuleNotFound < StandardError; end
end
