# frozen_string_literal: true

require 'rails_helper'

describe TimesliceDurationController, type: :request do
  describe '#index' do
    let(:user) { create(:user) }
    let(:superadmin) { create(:admin, permissions: 3) }

    context 'when the user is a superadmin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user)
          .and_return(superadmin)
      end

      it 'shows the feature to update timeslice duration' do
        get timeslice_duration_path
        expect(response.status).to eq(200)
      end
    end

    context 'when the user is not an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'returns a 401 error' do
        get timeslice_duration_path
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#show' do
    let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:course) { create(:course) }
    let(:superadmin) { create(:admin, permissions: 3) }
    let(:timeslice_duration_update_path) { '/timeslice_duration/update' }

    context 'when the course does not exist' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user)
          .and_return(superadmin)
        get timeslice_duration_update_path, params: { course_id: -1 }
      end

      it 'renders the error' do
        expect(response).to redirect_to(timeslice_duration_path)
        expect(flash[:error]).to eq('Course not found')
      end
    end

    context 'when the course exists' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user)
          .and_return(superadmin)
        get timeslice_duration_update_path, params: { course_id: course.id }
      end

      it 'renders the timeslice duration' do
        expect(response.status).to eq(200)
        expect(response.body).to include(wiki.domain)
        expect(response.body).to include(TimesliceManager::TIMESLICE_DURATION.to_s)
      end
    end
  end

  describe '#update' do
    let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:course) { create(:course) }
    let(:superadmin) { create(:admin, permissions: 3) }
    let(:timeslice_duration_update_path) { '/timeslice_duration/update' }

    context 'when the wiki does not exist' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user)
          .and_return(superadmin)
        post timeslice_duration_update_path, params: { course_id: course.id, wiki_id: 145 }
      end

      it 'renders the error' do
        expect(response).to redirect_to(timeslice_duration_path)
        expect(flash[:error]).to eq('Wiki not found')
      end
    end

    context 'when the update is successful' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user)
          .and_return(superadmin)
        post timeslice_duration_update_path, params: {
          course_id: course.id, duration: 456789, wiki_id: wiki.id
        }
        course.reload
      end

      it 'updates the timeslice duration and renders the success message' do
        expect(course.flags[:timeslice_duration][wiki.domain.to_sym]).to eq(456789)
        expect(response).to redirect_to(timeslice_duration_path)
        expect(flash[:notice])
          .to eq("Timeslice duration updated for course id #{course.id} wiki id #{wiki.id}")
      end
    end
  end
end
