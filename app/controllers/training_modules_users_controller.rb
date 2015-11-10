class TrainingModulesUsersController < ApplicationController
  respond_to :json

  def create_or_update
    training_module = TrainingModule.find_by(slug: params[:module_id])
    tmu = find_or_create_tmu(params, training_module.id)
    return complete_module(training_module, tmu) if params[:module_completed] == 'true'
    slide = TrainingSlide.find_by(slug: params[:slide_id])
    progress_manager = TrainingProgressManager.new(current_user, training_module, slide)
    complete_slide(tmu) if should_set_last_slide_completed?(tmu, progress_manager)
    render json: { slide: slide }
  end

  private

  def find_or_create_tmu(params, module_id)
    TrainingModulesUsers.find_or_initialize_by(
      user_id: params[:user_id],
      training_module_id: module_id
    )
  end

  def complete_slide(tmu)
    tmu.last_slide_completed = params[:slide_id]
    tmu.save
  end

  def complete_module(training_module, tmu)
    last_slide = training_module.slides.last.slug
    tmu.update_attributes(completed_at: Time.now, last_slide_completed: last_slide)
    render json: { library_id: params[:library_id], module_id: training_module.slug }
  end

  def should_set_last_slide_completed?(tmu, progress_manager)
    last = tmu.last_slide_completed
    tmu.last_slide_completed.nil? || progress_manager.current_slide_further_than_previous?(last)
  end
end
