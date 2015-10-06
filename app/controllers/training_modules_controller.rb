class TrainingModulesController < ApplicationController
  respond_to :json

  def index
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end


end
