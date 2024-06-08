# frozen_string_literal: true

class TrainingLibraryController < ApplicationController
  before_action :find_library_by_slug, only: [:create_category]

  def create_library
    training_library = TrainingLibrary.new(training_library_params)
    if training_library.save
      render json: { status: 'success', data: training_library }, status: :created
    else
      render json: { status: 'error', errorMessages: training_library.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  def create_category
    if category_exists?(training_category_params[:title])
      render json: { status: 'error', errorMessages: [I18n.t('training.validation.category')] },
             status: :unprocessable_entity
      return
    end
    if @library.add_category(training_category_params)
      render json: { status: 'success', data: @library }, status: :created
    else
      render json: { status: 'error', errorMessages: @library.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  private

  def find_library_by_slug
    @library = TrainingLibrary.find_by(slug: params[:library_id])
    if @library.nil?
      render json: { status: 'error', errorMessages: [I18n.t('training.validation.lib_notFound')] },
             status: :not_found
    end
  end

  def category_exists?(title)
    lowercase_title = title.downcase
    @library.categories.any? { |category| category['title'].downcase == lowercase_title }
  end

  # Strong parameters method to permit necessary fields
  def training_library_params
    params.require(:training_library).permit(:name, :slug, :introduction)
  end

  def training_category_params
    params.require(:category).permit(:title, :description)
  end
end
