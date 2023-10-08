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
    training_module = TrainingModule.find_by(id: params[:module_id])

    raise ActiveRecord::RecordNotFound unless training_module

    training_module_slug = "%slug: " + training_module.slug + "\n%"
    training_library = TrainingLibrary.find_by("categories LIKE ?", training_module_slug)

    raise ActiveRecord::RecordNotFound unless training_library

    redirect_to "/training/#{training_library.slug}/#{training_module.slug}"
  end
end
