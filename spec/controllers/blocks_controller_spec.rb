# frozen_string_literal: true

require 'rails_helper'

describe BlocksController, type: :request do
  describe '#destroy' do
    let!(:block) { create(:block) }
    let(:admin) { create(:admin, id: 2) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    it 'destroys the block' do
      expect(Block.count).to eq(1)
      delete "/blocks/#{block.id}", params: { id: block.id, format: :json }
      expect(Block.count).to eq(0)
    end
  end
end
