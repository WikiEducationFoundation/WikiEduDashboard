# frozen_string_literal: true

class TrainingModulesController < ApplicationController
  include TrainingHelper
  respond_to :json

  def index
    @training_modules = TrainingModule.all.sort_by(&:id)
    @training_libraries = TrainingLibrary.all
  end

  def show
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end

  def find
    training_module = TrainingModule.find(params[:module_id])
    training_library = find_library_from_module_slug(training_module.slug)
    raise ActionController::RoutingError, 'library not found' unless training_library
    redirect_to "/training/#{training_library.slug}/#{training_module.slug}"
  end
end
