# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/special_users'

describe SpecialUsers do
  let(:user) { create(:user) }

  describe 'Wikipedia Expert roles' do
    let(:role) { 'wikipedia_experts' }

    it 'can be added and removed' do
      expect(described_class.wikipedia_experts.count).to eq(0)
      described_class.set_user(role, user.username)
      expect(described_class.wikipedia_experts.count).to eq(1)
      described_class.remove_user(role, username: user.username)
      expect(described_class.wikipedia_experts.count).to eq(0)
    end
  end
end
