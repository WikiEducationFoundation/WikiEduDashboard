# frozen_string_literal: true

class TrainingModulesController < ApplicationController
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
    # Use a specific training library for the module, or a default library if it is not found
    training_library = training_module.find_or_default_library
    redirect_to "/training/#{training_library.slug}/#{training_module.slug}"
  end
end
