# frozen_string_literal: true

require 'rails_helper'

describe WeeksController, type: :request do
  describe '#destroy' do
    let(:course) { create(:course) }
    let!(:week) { create(:week, course_id: course.id) }
    let(:admin) { create(:admin, id: 2) }
    let(:user) { create(:user) }
    let(:course_approved) do
      course.campaigns << Campaign.first
    end

    context 'when user is not signed in' do
      it 'returns 401' do
        delete "/weeks/#{week.id}", params: { id: week.id, format: :json }
        expect(response.status).to eq(401)
        expect(Week.count).to eq(1)
      end
    end

    context 'when user cannot edit the course' do
      before do
        allow_any_instance_of(ApplicationController)
          .to receive(:current_user).and_return(user)
      end

      it 'returns 401' do
        delete "/weeks/#{week.id}", params: { id: week.id, format: :json }
        expect(response.status).to eq(401)
        expect(Week.count).to eq(1)
      end
    end

    context 'when user can edit the course' do
      before do
        allow_any_instance_of(ApplicationController)
          .to receive(:current_user).and_return(admin)
      end

      it 'does not create an alert when course is not approved' do
        expect(Week.count).to eq(1)
        delete "/weeks/#{week.id}", params: { id: week.id, format: :json }
        expect(Week.count).to eq(0)
        expect(CheckTimelineAlert.count).to eq(0)
      end

      it 'creates an alert when course is approved' do
        course_approved
        expect(Week.count).to eq(1)
        delete "/weeks/#{week.id}", params: { id: week.id, format: :json }
        expect(Week.count).to eq(0)
        expect(CheckTimelineAlert.count).to eq(1)
      end
    end
  end
end
