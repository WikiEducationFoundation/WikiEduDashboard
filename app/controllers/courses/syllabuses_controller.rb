# frozen_string_literal: true
class Courses::SyllabusesController < ApplicationController
  before_action :validate, only: :update

  def update
    handle_syllabus_params
    if @course.save
      render json: { success: true, url: @course.syllabus.url }
    else
      render json: { message: I18n.t('error.invalid_file_format') },
             status: :unprocessable_entity
    end
  end

  private

  def validate
    @course = Course.find(params[:id])
    raise NotPermittedError unless current_user&.can_edit?(@course)
  end

  def handle_syllabus_params
    syllabus = params['syllabus']
    if syllabus == 'null'
      @course.syllabus.destroy
      @course.syllabus = nil
    else
      @course.syllabus = params['syllabus']
    end
  end
end
