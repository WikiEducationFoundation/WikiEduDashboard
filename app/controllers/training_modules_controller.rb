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
end
