# frozen_string_literal: true

class TrainingLibraryController < ApplicationController
  def create
    training_library = TrainingLibrary.new(training_library_params)
    if training_library.save
      render json: { status: 'success', data: training_library }, status: :created
    else
      render json: { status: 'error', message: training_library.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  private

  # Strong parameters method to permit necessary fields
  def training_library_params
    params.require(:training_library).permit(:name, :slug, :introduction)
  end
end
