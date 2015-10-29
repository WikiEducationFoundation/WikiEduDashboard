class TrainingModulesUsersController < ApplicationController
  respond_to :json

  def create_or_update
    training_module = TrainingModule.find_by(slug: params[:module_id])
    module_id = training_module.id
    tmu = TrainingModulesUsers.find_or_initialize_by(
      user_id: params[:user_id],
      training_module_id: module_id
    )
    progress_manager = TrainingProgressManager.new(
      current_user,
      training_module,
      TrainingSlide.find_by(slug: params[:slide_id])
    )
    if tmu.last_slide_completed.nil? ||
      progress_manager.current_slide_further_than_previous?(tmu.last_slide_completed)
        tmu.last_slide_completed = params[:slide_id]
      tmu.save
    end
    render nothing: true
  end

end
