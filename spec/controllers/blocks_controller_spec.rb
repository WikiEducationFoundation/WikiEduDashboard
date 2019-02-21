# frozen_string_literal: true

require 'rails_helper'

describe BlocksController, type: :request do
  describe '#destroy' do
    let(:admin) { create(:admin, id: 2) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    it 'destroys the block' do
      id = create(:block).id
      expect(Block.count).to eq(1)
      delete "/blocks/#{id}", params: { id: id, format: :json }
      expect(Block.count).to eq(0)
    end

    it 'does not destroy the block if it cannot be deleted' do
      id = create(:block, is_deletable: false).id
      expect(Block.count).to eq(1)
      delete "/blocks/#{id}", params: { id: id, format: :json }
      expect(Block.count).to eq(1)
    end
  end
end
