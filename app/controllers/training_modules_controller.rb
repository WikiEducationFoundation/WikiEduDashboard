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
    training_library = training_module.find_or_default_library
    redirect_to "/training/#{training_library.slug}/#{training_module.slug}"
  end

  def add_module
    @library = find_library
    return unless @library

    category = find_category(@library)
    return unless category

    @module = create_module
    return unless @module.persisted?

    associate_module_with_category(category)
    save_library_with_module
  end

  private

  def find_library
    library_slug = params[:library_id]
    library = TrainingLibrary.find_by(slug: library_slug)
    unless library
      render json: { status: 'error',
                     errorMessages: ["Training library with slug '#{library_slug}' not found."] },
             status: :not_found
    end
    library
  end

  def find_category(library)
    category_title = params[:category_id]
    category = library.categories.find { |cat| cat['title'] == category_title }
    unless category
      render json: { status: 'error',
                     errorMessages: [
                       "Category '#{category_title}' not exist in library '#{library.slug}'."
                     ] },
             status: :not_found
    end
    category
  end

  def create_module
    training_module = TrainingModule.new(training_module_params)
    unless training_module.save
      render json: { status: 'error', errorMessages: training_module.errors.full_messages },
             status: :unprocessable_entity
    end
    training_module
  end

  def associate_module_with_category(category)
    category['modules'] ||= []
    category['modules'] << {
      'name' => @module.name,
      'slug' => @module.slug,
      'description' => @module.description
    }
  end

  def save_library_with_module
    if @library.save
      render json: { status: 'success', data: @module }, status: :created
    else
      render json: { status: 'error', errorMessages: @library.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  # Strong parameters method to permit necessary fields for module creation
  def training_module_params
    params.require(:module).permit(:name, :slug, :description)
  end
end
