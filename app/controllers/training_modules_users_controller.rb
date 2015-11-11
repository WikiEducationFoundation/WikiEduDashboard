class TrainingModulesUsersController < ApplicationController
  respond_to :json

  def create_or_update
    training_module = TrainingModule.find_by(slug: params[:module_id])
    tmu = find_or_create_tmu(params, training_module.id)
    slide = TrainingSlide.find_by(slug: params[:slide_id])
    pm = TrainingProgressManager.new(current_user, training_module, slide)
    complete_slide(tmu, slide) if should_set_slide_completed?(tmu, pm)
    complete_module(tmu) if is_last_slide?(tmu, slide)
    render json: { slide: slide }
  end

  private

  def find_or_create_tmu(params, module_id)
    TrainingModulesUsers.find_or_initialize_by(
      user_id: params[:user_id],
      training_module_id: module_id
    )
  end

  def complete_slide(tmu, slide)
    tmu.last_slide_completed = slide.slug
    tmu.save
    complete_module(tmu) if is_last_slide?(tmu, slide)
  end

  def complete_module(tmu)
    tmu.update_attribute(:completed_at, Time.now)
  end

  def is_last_slide?(tmu, slide)
    tmu.training_module.slides.last.slug == slide.slug
  end

  def should_set_slide_completed?(tmu, pm)
    last = tmu.last_slide_completed
    tmu.last_slide_completed.nil? || pm.current_slide_further_than_previous?(last)
  end
end
