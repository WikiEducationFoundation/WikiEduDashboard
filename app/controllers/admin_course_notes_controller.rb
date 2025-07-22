# frozen_string_literal: true

class AdminCourseNotesController < ApplicationController
  before_action :set_course_note, only: [:update, :destroy]

  def show
    admin_course_notes = AdminCourseNote.where(courses_id: params[:id])
    render json: { AdminCourseNotes: admin_course_notes }
  end

  def update
    if @admin_course_note.update_note(admin_course_note_params)
      render json: { success: true, admin_course_note: @admin_course_note }
    else
      render json: { error: 'Failed to update course note' }, status: :unprocessable_entity
    end
  end

  def create
    admin_course_note_details = AdminCourseNote.create(admin_course_note_params)
    if admin_course_note_details
      render json: { created_admin_course_note: admin_course_note_details }, status: :created
    else
      render json: { error: 'Failed to create course note' }, status: :unprocessable_entity
    end
  end

  def destroy
    if @admin_course_note.destroy
      render json: { success: true }
    else
      render json: { error: 'Failed to delete course note' }, status: :unprocessable_entity
    end
  end

  private

  def set_course_note
    @admin_course_note = AdminCourseNote.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Note not found' }, status: :not_found
  end

  def admin_course_note_params
    params.require(:admin_course_note).permit(:courses_id, :title,
                                              :text).merge(edited_by: current_user.username)
  end
end
