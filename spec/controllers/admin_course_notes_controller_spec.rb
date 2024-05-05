# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AdminCourseNotesController, type: :controller do
  before do
    allow(controller).to receive(:current_user).and_return(create(:user,
                                                                  username: 'example_username'))
  end

  describe 'GET #show' do
    it 'returns a success response with admin course notes' do
      course = create(:course)
      admin_course_note = create(:admin_course_note, course:)

      get :show, params: { id: course.id }

      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response['AdminCourseNotes']).to be_an(Array)
      expect(json_response['AdminCourseNotes'].length).to eq(1)
      expect(json_response['AdminCourseNotes'][0]['id']).to eq(admin_course_note.id)
    end
  end

  describe 'PATCH #update' do
    let(:admin_course_note) { create(:admin_course_note) }

    it 'updates the admin course note and returns success' do
      patch :update, params: { id: admin_course_note.id, admin_course_note: { title: 'Updated Title' } }

      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be_truthy
      expect(admin_course_note.reload.title).to eq('Updated Title')
    end

    it 'returns unprocessable entity on update failure' do
      allow_any_instance_of(AdminCourseNote).to receive(:update_note).and_return(false)
      patch :update, params: { id: admin_course_note.id, admin_course_note: { title: 'Updated Title' } }

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Failed to update course note')
    end
  end

  describe 'POST #create' do
    let(:course) { create(:course) }

    it 'creates a new admin course note and returns created' do
      post :create, params: { admin_course_note: { courses_id: course.id, title: 'New Note', text: 'Note Text' } }

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['created_admin_course_note']).to be_a(Hash)
    end
  end

  describe 'DELETE #destroy' do
    let(:admin_course_note) { create(:admin_course_note) }

    it 'destroys the admin course note and returns success' do
      delete :destroy, params: { id: admin_course_note.id }

      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be_truthy
      expect { admin_course_note.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns unprocessable entity on destroy failure' do
      allow_any_instance_of(AdminCourseNote).to receive(:destroy).and_return(false)
      delete :destroy, params: { id: admin_course_note.id }

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Failed to delete course note')
    end
  end
end
