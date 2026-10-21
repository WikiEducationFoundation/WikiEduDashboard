# frozen_string_literal: true

class TrainingModulesController < ApplicationController
  respond_to :json

  def index
    @training_modules = TrainingModule.all.sort_by(&:id)
    @training_libraries = TrainingLibrary.all
  end

  def show
    @training_module = TrainingModule.find_by(slug: params[:module_id])
    set_needs_exercise_article if @training_module&.article_title_input && current_user
  end

  def find
    training_module = TrainingModule.find(params[:module_id])
    # Use a specific training library for the module, or a default library if it is not found
    training_library = training_module.find_or_default_library
    redirect_to "/training/#{training_library.slug}/#{training_module.slug}"
  end

  private

  # The slides ask for the exercise article only from a student it counts for,
  # and only until the exercise is complete in each of their current courses.
  # Completions from before it needed an article count, without one.
  def set_needs_exercise_article
    tmu = TrainingModulesUsers.find_by(user: current_user, training_module: @training_module)
    courses = VerifyExerciseArticle.current_courses(user: current_user,
                                                    training_module: @training_module)
    @needs_exercise_article = courses.any? { |c| !tmu&.flags&.dig(c.id, :marked_complete) }
  end
end
