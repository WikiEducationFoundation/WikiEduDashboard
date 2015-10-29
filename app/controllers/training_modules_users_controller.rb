class TrainingModulesUsersController < ApplicationController
  respond_to :json

  def create_or_update
    training_module = TrainingModule.find_by(slug: params[:module_id])
    module_id = training_module.id
    tmu = TrainingModulesUsers.find_or_initialize_by(
      user_id: params[:user_id],
      training_module_id: module_id
    )
    if params[:module_completed] == 'true'
      tmu.update_attributes(
        completed_at: Time.now,
        last_slide_completed: training_module.slides.last.slug
      )
      render json: {
        library_id: params[:library_id],
        module_id: training_module.slug
      } and return
    end
    slide = TrainingSlide.find_by(slug: params[:slide_id])
    progress_manager = TrainingProgressManager.new(
      current_user,
      training_module,
      slide
    )
    if tmu.last_slide_completed.nil? ||
      progress_manager.current_slide_further_than_previous?(tmu.last_slide_completed)
        tmu.last_slide_completed = params[:slide_id]
      tmu.save
    end
    render json: { slide: slide }
  end

end
