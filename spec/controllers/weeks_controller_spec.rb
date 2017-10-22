# frozen_string_literal: true

require 'rails_helper'

describe WeeksController do
  describe '#destroy' do
    let!(:week) { create(:week) }
    let(:admin) { create(:admin, id: 2) }

    before do
      allow(controller).to receive(:current_user).and_return(admin)
    end

    it 'destroys the week' do
      expect(Week.count).to eq(1)
      delete :destroy, params: { id: week.id }, format: :json
      expect(Week.count).to eq(0)
    end
  end
end
