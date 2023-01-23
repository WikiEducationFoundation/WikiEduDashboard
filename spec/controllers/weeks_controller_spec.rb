# frozen_string_literal: true

require 'rails_helper'

describe WeeksController, type: :request do
  describe '#destroy' do
    let(:course) { create(:course) }
    let!(:week) { create(:week, course_id: course.id) }
    let(:admin) { create(:admin, id: 2) }
    let(:course_approved) do
      course.campaigns << Campaign.first
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    context 'when course is not approved' do
      it 'does not create an alert, only destroys the week' do
        expect(Week.count).to eq(1)
        delete "/weeks/#{week.id}", params: { id: week.id, format: :json }
        expect(Week.count).to eq(0)
        expect(Alert.count).to eq(0)
      end
    end

    context 'when course is approved' do
      it 'create an alert and destroys the week' do
        course_approved
        expect(Week.count).to eq(1)
        delete "/weeks/#{week.id}", params: { id: week.id, format: :json }
        expect(Week.count).to eq(0)
        expect(Alert.count).to eq(1)
      end
    end
  end
end
