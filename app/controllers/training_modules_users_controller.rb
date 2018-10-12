# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training_module"

class TrainingModulesUsersController < ApplicationController
  respond_to :json

  def create_or_update
    set_slide
    @training_module_user = find_or_create_tmu(params)
    return if @slide.nil?
    complete_slide if should_set_slide_completed?
    complete_module if last_slide?
    @completed = @training_module_user.completed_at.present?
    render_slide
  end

  private

  def set_slide
    @training_module = TrainingModule.find_by(slug: params[:module_id])
    @slide = TrainingSlide.find_by(slug: params[:slide_id])
  end

  def render_slide
    render json: { slide: @slide, completed: @completed }
  end

  def find_or_create_tmu(params)
    TrainingModulesUsers.find_or_initialize_by(
      user_id: params[:user_id],
      training_module_id: @training_module.id
    )
  end

  def complete_slide
    @training_module_user.last_slide_completed = @slide.slug
    @training_module_user.save
  end

  def complete_module
    @training_module_user.update_attribute(:completed_at, Time.now.utc)
  end

  def last_slide?
    @training_module_user.training_module.slides.last.slug == @slide.slug
  end

  def should_set_slide_completed?
    @training_module_user.furthest_slide?(@slide.slug)
  end
end
