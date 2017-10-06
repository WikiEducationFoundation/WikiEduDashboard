# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/productive_course_alert_manager"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe ProductiveCourseAlertManager do
  let(:course) { create(:course, user_count: user_count, character_sum: character_sum) }
  let(:subject) { ProductiveCourseAlertManager.new([course]) }

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
      expect(Alert.last.type).to eq('ProductiveCourseAlert')
      expect(Alert.last.email_sent_at).not_to be_nil
    end
  end

  context 'when productivity is high but there is already an alert' do
    let(:user_count) { 5 }
    let(:character_sum) { 50_000 }
    before { create(:alert, type: 'ProductiveCourseAlert', course_id: course.id) }

    it 'does not create an alert' do
      subject.create_alerts
      expect(Alert.count).to eq(1)
    end
  end
end
