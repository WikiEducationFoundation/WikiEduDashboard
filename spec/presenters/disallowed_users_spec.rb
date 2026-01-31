# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/disallowed_users'

describe DisallowedUsers do
  let(:user) { create(:user) }

  describe '.disallowed_usernames' do
    it 'returns an empty array when no users are disallowed' do
      expect(described_class.disallowed_usernames).to eq([])
    end
  end

  describe '.add_user' do
    it 'adds a username to the disallowed list' do
      expect(described_class.disallowed_usernames).not_to include(user.username)
      described_class.add_user(user.username)
      expect(described_class.disallowed_usernames).to include(user.username)
    end

    it 'returns true when user is successfully added' do
      expect(described_class.add_user(user.username)).to be true
    end

    it 'returns false when user is already in the list' do
      described_class.add_user(user.username)
      expect(described_class.add_user(user.username)).to be false
    end
  end

  describe '.remove_user' do
    before do
      described_class.add_user(user.username)
    end

    it 'removes a username from the disallowed list' do
      expect(described_class.disallowed_usernames).to include(user.username)
      described_class.remove_user(user.username)
      expect(described_class.disallowed_usernames).not_to include(user.username)
    end

    it 'returns true when user is successfully removed' do
      expect(described_class.remove_user(user.username)).to be true
    end

    it 'returns false when user is not in the list' do
      described_class.remove_user(user.username)
      expect(described_class.remove_user(user.username)).to be false
    end
  end

  describe '.disallowed?' do
    it 'returns true when username is in the disallowed list' do
      described_class.add_user(user.username)
      expect(described_class.disallowed?(user.username)).to be true
    end

    it 'returns false when username is not in the disallowed list' do
      expect(described_class.disallowed?(user.username)).to be false
    end
  end
end
