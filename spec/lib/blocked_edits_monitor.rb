# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/blocked_edits_monitor"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe BlockedEditsMonitor do
  describe '.create_alert' do
    let(:student) { create(:user, username: 'student') }
    let(:student2) { create(:user, username: 'student2') }
    it 'creates an Alert record for a blocked edit' do
      BlockedEditsMonitor.create_alerts_for_blocked_edits(student)
      expect(Alert.count).to eq(1)
    end

    it 'does not create multiple alerts' do
      BlockedEditsMonitor.create_alerts_for_blocked_edits(student)
      BlockedEditsMonitor.create_alerts_for_blocked_edits(student2)
      expect(Alert.count).to eq(1)
    end
  end
end
