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
   # set_training_library
    @find_training_module ||= if is_number?(params[:module_id])
      TrainingModule.find_by(id: params[:module_id])
    else
      TrainingModule.find_by(slug: params[:module_id])
    end
    find_corresponding_library
    redirect_to "/training/#{@find_training_library.slug}/#{@find_training_module.slug}"

  end

  def find_corresponding_library
    @find_training_library ||= if is_number?(params[:module_id])
    #@find_training_library = TrainingLibrary.all.select(:categories).select(:modules).where("slug = ?", params[:module_id])
      TrainingLibrary.all.where("categories.modules.id LIKE ?", params[:module_id])
    else
      TrainingLibrary.all.where("categories.modules.slug LIKE ?", params[:module_id]) 
    end
  end

    private
    def is_number?(string)
      string.to_i.to_s == string
    end

    def set_training_library
      @library = TrainingLibrary.find_by(slug: params[:library_id])
    end
end