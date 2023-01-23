# frozen_string_literal: true

require 'rails_helper'

describe BlocksController, type: :request do
  describe '#destroy' do
    let(:course) { create(:course) }
    let!(:week) { create(:week, course_id: course.id) }
    let!(:block) { create(:block, week_id: week.id) }
    let(:admin) { create(:admin, id: 2) }
    let(:course_approved) do
      course.campaigns << Campaign.first
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    context 'when course is not approved' do
      it 'does not create an alert, only destroys the block' do
        expect(Block.count).to eq(1)
        delete "/blocks/#{block.id}", params: { id: block.id, format: :json }
        expect(Block.count).to eq(0)
        expect(Alert.count).to eq(0)
      end
    end

    context 'when course is approved' do
      it 'create an alert and destroys the block' do
        course_approved
        expect(Block.count).to eq(1)
        delete "/blocks/#{block.id}", params: { id: block.id, format: :json }
        expect(Block.count).to eq(0)
        expect(Alert.count).to eq(1)
      end
    end
  end
end
