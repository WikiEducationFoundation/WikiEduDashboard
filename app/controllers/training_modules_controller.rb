class TrainingModulesController < ApplicationController
  respond_to :json

  def index
    @training_modules = TrainingModule.all.sort {|a, b| a.id <=> b.id }
  end

  def show
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end

  def by_id
    @training_module = TrainingModule.find(params[:id].to_i)
    render 'for_block'
  end

  def for_block
    @training_module = Block.find(params[:block_id]).training_module
  end

end
