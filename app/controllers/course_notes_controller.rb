# frozen_string_literal: true

class CourseNotesController < ApplicationController
  before_action :set_course_note, only: [:find_course_note, :update, :destroy]

  def show
    course_notes = CourseNote.where(courses_id: params[:id])
    render json: { courseNotes: course_notes }
  end

  def find_course_note
    render json: { courseNote: @course_note }
  end

  def update
    if @course_note.update_note(course_note_params)
      render json: { success: true }
    else
      render json: { error: 'Failed to update course note' }, status: :unprocessable_entity
    end
  end

  def create
    note_details = CourseNote.create(course_note_params)
    if note_details
      render json: { createdNote: note_details }, status: :created
    else
      render json: { error: 'Failed to create course note' }, status: :unprocessable_entity
    end
  end

  def destroy
    if @course_note.destroy
      render json: { success: true }
    else
      render json: { error: 'Failed to delete course note' }, status: :unprocessable_entity
    end
  end

  private

  def set_course_note
    @course_note = CourseNote.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Note not found' }, status: :not_found
  end

  def course_note_params
    params.require(:course_note).permit(:courses_id, :title,
                                        :text).merge(edited_by: current_user.username)
  end
end
