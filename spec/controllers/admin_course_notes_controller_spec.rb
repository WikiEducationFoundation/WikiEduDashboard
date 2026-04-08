# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AdminCourseNotesController, type: :controller do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:admin_course_note) { create(:admin_course_note, course:) }

  describe 'authorization' do
    it 'returns 401 for non-admin on show' do
      allow(controller).to receive(:current_user).and_return(user)
      get :show, params: { id: course.id }
      expect(response.status).to eq(401)
    end

    it 'returns 401 for non-admin on create' do
      allow(controller).to receive(:current_user).and_return(user)
      post :create, params: {
        admin_course_note: { courses_id: course.id, title: 'X', text: 'Y' }
      }
      expect(response.status).to eq(401)
    end

    it 'returns 401 for non-admin on update' do
      allow(controller).to receive(:current_user).and_return(user)
      patch :update, params: {
        id: admin_course_note.id, admin_course_note: { title: 'X' }
      }
      expect(response.status).to eq(401)
    end

    it 'returns 401 for non-admin on destroy' do
      allow(controller).to receive(:current_user).and_return(user)
      delete :destroy, params: { id: admin_course_note.id }
      expect(response.status).to eq(401)
    end
  end

  context 'when user is an admin' do
    before do
      allow(controller).to receive(:current_user).and_return(admin)
    end

    describe 'GET #show' do
      it 'returns a success response with admin course notes' do
        admin_course_note # ensure it exists
        get :show, params: { id: course.id }

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['AdminCourseNotes']).to be_an(Array)
        expect(json_response['AdminCourseNotes'].length).to eq(1)
        expect(json_response['AdminCourseNotes'][0]['id']).to eq(admin_course_note.id)
      end
    end

    describe 'PATCH #update' do
      it 'updates the admin course note and returns success' do
        patch :update,
              params: { id: admin_course_note.id,
                        admin_course_note: { title: 'Updated Title' } }

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be_truthy
        expect(admin_course_note.reload.title).to eq('Updated Title')
      end

      it 'returns unprocessable entity on update failure' do
        allow_any_instance_of(AdminCourseNote).to receive(:update_note)
          .and_return(false)
        patch :update,
              params: { id: admin_course_note.id,
                        admin_course_note: { title: 'Updated Title' } }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Failed to update course note')
      end
    end

    describe 'POST #create' do
      it 'creates a new admin course note and returns created' do
        post :create,
             params: { admin_course_note: { courses_id: course.id,
                                            title: 'New Note',
                                            text: 'Note Text' } }

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['created_admin_course_note']).to be_a(Hash)
      end
    end

    describe 'DELETE #destroy' do
      it 'destroys the admin course note and returns success' do
        delete :destroy, params: { id: admin_course_note.id }

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be_truthy
        expect { admin_course_note.reload }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns unprocessable entity on destroy failure' do
        allow_any_instance_of(AdminCourseNote).to receive(:destroy)
          .and_return(false)
        delete :destroy, params: { id: admin_course_note.id }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Failed to delete course note')
      end
    end
  end
end
