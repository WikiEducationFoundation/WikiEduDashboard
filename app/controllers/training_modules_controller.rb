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
 
  #new code
  def find
    @find_training_module ||= if is_number?(params[:module_id])
      TrainingModule.find_by(id: params[:module_id])
    else
      TrainingModule.find_by(slug: params[:module_id])
    end
    redirect_to "/training/students/#{@find_training_module.slug}"

  end

    private
    def is_number?(string)
      string.to_i.to_s == string
    end
end