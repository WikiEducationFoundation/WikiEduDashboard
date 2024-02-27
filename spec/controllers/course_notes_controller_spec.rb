# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CourseNotesController, type: :controller do
  describe 'GET #show' do
    it 'returns a success response with course notes' do
      course = create(:course)
      course_note = create(:course_note, course:)

      get :show, params: { id: course.id }
      expect(response).to be_successful

      json_response = JSON.parse(response.body)
      expect(json_response['courseNotes']).to be_an(Array)
      expect(json_response['courseNotes'].length).to eq(1)
      expect(json_response['courseNotes'][0]['id']).to eq(course_note.id)
    end
  end

  describe 'GET #find_course_note' do
    let(:course) { create(:course) }

    it 'returns a success response with a single course note' do
      course_note = create(:course_note, course:)

      get :find_course_note, params: { id: course_note.id }
      expect(response).to be_successful

      json_response = JSON.parse(response.body)
      expect(json_response['courseNote']).to be_a(Hash)
      expect(json_response['courseNote']['id']).to eq(course_note.id)
    end

    it 'returns not found for an unknown course note' do
      get :find_course_note, params: { id: 999 }
      expect(response).to have_http_status(:not_found)

      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Note not found')
    end
  end

  describe 'PATCH #update' do
    let(:course_note) { create(:course_note) }

    it 'updates the course note and returns success' do
      patch :update, params: { id: course_note.id, course_note: { title: 'Updated Title' } }
      expect(response).to be_successful

      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be_truthy

      expect(course_note.reload.title).to eq('Updated Title')
    end

    it 'returns unprocessable entity on update failure' do
      allow_any_instance_of(CourseNote).to receive(:update_note).and_return(false)

      patch :update, params: { id: course_note.id, course_note: { title: 'Updated Title' } }
      expect(response).to have_http_status(:unprocessable_entity)

      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Failed to update course note')
    end
  end

  describe 'POST #create' do
    let(:course) { create(:course) }

    it 'creates a new course note and returns created' do
      post :create, params: { course_note: { courses_id: course.id, title: 'New Note',
      text: 'Note Text', edited_by: 'User' } }

      expect(response).to have_http_status(:created)

      json_response = JSON.parse(response.body)
      expect(json_response['createdNote']).to be_a(Hash)
    end
  end

  describe 'DELETE #destroy' do
    let(:course_note) { create(:course_note) }

    it 'destroys the course note and returns success' do
      delete :destroy, params: { id: course_note.id }
      expect(response).to be_successful

      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be_truthy

      expect { course_note.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns unprocessable entity on destroy failure' do
      allow_any_instance_of(CourseNote).to receive(:destroy).and_return(false)

      delete :destroy, params: { id: course_note.id }
      expect(response).to have_http_status(:unprocessable_entity)

      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Failed to delete course note')
    end
  end
end
