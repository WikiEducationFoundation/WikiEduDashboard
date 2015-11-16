class TrainingModulesController < ApplicationController
  respond_to :json

  def index
    @training_modules = TrainingModule.all.sort {|a, b| a.id <=> b.id }
  end

  def show
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end
end
