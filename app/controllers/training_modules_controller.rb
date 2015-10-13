class TrainingModulesController < ApplicationController
  respond_to :json

  def index
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end

  def for_block
    @training_module = Block.find(params[:block_id]).training_module
  end

end
