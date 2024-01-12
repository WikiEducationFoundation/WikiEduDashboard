# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/alerts/blocked_user_monitor')

describe BlockedUserMonitor do
  describe '.create_alerts_for_recently_blocked_users' do
    let(:user) { create(:user, username: 'Verdantpowerinc') }
    let(:course) { create(:course) }

    before do
      create(:courses_user, user:, course:)
      stub_block_log_query
    end

    it 'creates an Alert record for a blocked user' do
      expect(Alert.count).to eq(0)
      described_class.create_alerts_for_recently_blocked_users
      expect(Alert.count).to eq(1)
    end

    it 'does not create multiple alerts for the same block' do
      expect(Alert.count).to eq(0)
      described_class.create_alerts_for_recently_blocked_users
      described_class.create_alerts_for_recently_blocked_users
      expect(Alert.count).to eq(1)
    end
  end
end
