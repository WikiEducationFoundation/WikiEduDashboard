# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/active_course_alert_manager"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe ActiveCourseAlertManager do
  let(:course) { create(:course, user_count: user_count, character_sum: character_sum) }
  let(:subject) { ActiveCourseAlertManager.new([course]) }

  before do
    create(:user, username: 'Eryk (Wiki Ed)', email: 'eryk@wikiedu.org')
    create(:setting, key: 'special_users', value: { communications_manager: 'Eryk (Wiki Ed)' })
  end

  context 'when there are no users' do
    let(:user_count) { 0 }
    let(:character_sum) { 0 }

    it 'does not create an alert' do
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end

  context 'when user productivity is low' do
    let(:user_count) { 5 }
    let(:character_sum) { 100 }
    it 'does not create an alert' do
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end

  context 'when user productivity is high' do
    let(:user_count) { 5 }
    let(:character_sum) { 50_000 }
    it 'creates an alert and sends an email' do
      subject.create_alerts
      expect(Alert.count).to eq(1)
      expect(Alert.last.type).to eq('ActiveCourseAlert')
      expect(Alert.last.email_sent_at).not_to be_nil
    end
  end

  context 'when productivity is high but there is already an alert' do
    let(:user_count) { 5 }
    let(:character_sum) { 50_000 }
    before { create(:alert, type: 'ActiveCourseAlert', course_id: course.id) }

    it 'does not create an alert' do
      subject.create_alerts
      expect(Alert.count).to eq(1)
    end
  end
end
