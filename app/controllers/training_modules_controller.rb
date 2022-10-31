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
    find_corresponding_library
    redirect_to "/training/#{@library_slug}/#{@find_training_module.slug}"

  end

  def find_corresponding_library
  @training_library = TrainingLibrary.all.find_each do |library|
   categories = library.categories
   @library_slug = library.slug
   categories.each do |key, value|
     puts key
     puts value
     if key == 'modules'
      puts value[1].each do |key, value|
        puts key
        puts value.include?(@find_training_module.slug)
        @library_slug
      end
     end
    end
  end
  end

    private
    def is_number?(string)
      string.to_i.to_s == string
    end
 end
