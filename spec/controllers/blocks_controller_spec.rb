# frozen_string_literal: true

require 'rails_helper'

describe BlocksController, type: :request do
  describe '#destroy' do
    let(:course) { create(:course) }
    let!(:week) { create(:week, course_id: course.id) }
    let!(:block) { create(:block, week_id: week.id) }
    let(:admin) { create(:admin, id: 2) }
    let(:user) { create(:user) }
    let(:course_approved) do
      course.campaigns << Campaign.first
    end

    context 'when user is not signed in' do
      it 'returns 401' do
        delete "/blocks/#{block.id}", params: { id: block.id, format: :json }
        expect(response.status).to eq(401)
        expect(Block.count).to eq(1)
      end
    end

    context 'when user cannot edit the course' do
      before do
        allow_any_instance_of(ApplicationController)
          .to receive(:current_user).and_return(user)
      end

      it 'returns 401' do
        delete "/blocks/#{block.id}", params: { id: block.id, format: :json }
        expect(response.status).to eq(401)
        expect(Block.count).to eq(1)
      end
    end

    context 'when user can edit the course' do
      before do
        allow_any_instance_of(ApplicationController)
          .to receive(:current_user).and_return(admin)
      end

      it 'does not create an alert when course is not approved' do
        expect(Block.count).to eq(1)
        delete "/blocks/#{block.id}", params: { id: block.id, format: :json }
        expect(Block.count).to eq(0)
        expect(CheckTimelineAlert.count).to eq(0)
      end

      it 'creates an alert when course is approved' do
        course_approved
        expect(Block.count).to eq(1)
        delete "/blocks/#{block.id}", params: { id: block.id, format: :json }
        expect(Block.count).to eq(0)
        expect(CheckTimelineAlert.count).to eq(1)
      end
    end
  end
end
