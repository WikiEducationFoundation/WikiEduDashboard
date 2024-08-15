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

    associate_module_with_category(category, @module)
    save_library_with_response
  end

  def transfer_modules
    @library = find_library
    return unless @library

    source_category = find_category(@library, transfer_info_params[:sourceCategory])
    return unless source_category

    destination_category = find_category(@library, transfer_info_params[:destinationCategory])
    return unless destination_category

    modules_to_move = find_modules_to_move(source_category, transfer_info_params[:modules])
    move_modules(modules_to_move, source_category, destination_category)
    save_library_with_response
  end

  def reorder_slides
    @training_module = find_training_module
    return unless @training_module

    reordered_slides = reordered_slides_params
    if @training_module.update(slide_slugs: reordered_slides)
      render json: { status: 'success' }, status: :ok
    else
      render json: { status: 'error', errorMessages: @training_module.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  private

  # Find the training library by slug
  def find_library
    library = TrainingLibrary.find_by(slug: params[:library_id])
    unless library
      render json: { status: 'error',
             errorMessages: ["Training library with slug '#{params[:library_id]}' not found."] },
             status: :not_found
    end
    library
  end

  def find_training_module
    training_module = TrainingModule.find_by(slug: params[:module_id])
    unless training_module
      render json: { status: 'error', errorMessages: ["Training module not found."] },
             status: :not_found
    end
    training_module
  end

  # Find the category within the library by title
  def find_category(library, category_title = params[:category_id])
    category = library.categories.find { |cat| cat['title'] == category_title }
    error_message = "Category '#{category_title}' not exist in library '#{library.slug}'."
    unless category
      render json: { status: 'error',
             errorMessages: [error_message] },
             status: :not_found
    end
    category
  end

  # Create a new training module
  def create_module
    training_module = TrainingModule.new(training_module_params)
    unless training_module.save
      render json: { status: 'error', errorMessages: training_module.errors.full_messages },
             status: :unprocessable_entity
    end
    training_module
  end

  # Associate a module with a category
  def associate_module_with_category(category, training_module)
    category['modules'] ||= []
    category['modules'] << {
      'name' => training_module.name,
      'slug' => training_module.slug,
      'description' => training_module.description
    }
  end

  # Save the library and render response
  def save_library_with_response
    if @library.save
      render json: { status: 'success', data: @module }, status: :created
    else
      render json: { status: 'error', errorMessages: @library.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  # Find modules to be moved by names
  def find_modules_to_move(category, module_names)
    category['modules'].select { |mod| module_names.include?(mod['name']) }
  end

  # Move modules from source to destination category
  def move_modules(modules, source_category, destination_category)
    modules.each do |module_to_move|
      destination_category['modules'] << module_to_move
    end
    source_category['modules'].reject! { |mod| modules.map { |m| m['name'] }.include?(mod['name']) }
  end

  # Strong parameters for training module creation
  def training_module_params
    params.require(:module).permit(:name, :slug, :description)
  end

  # Strong parameters for transfer info
  def transfer_info_params
    params.require(:transferInfo).permit(:sourceCategory, :destinationCategory, modules: [])
  end

  # Strong parameter for reorder slides
  def reordered_slides_params
    params.require(:reorderedSlides)
  end
end
