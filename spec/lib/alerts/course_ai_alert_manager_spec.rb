# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/course_ai_alert_manager"

describe CourseAiAlertManager do
  let(:course) { create(:course) }
  let(:subject) { described_class.new([course]) }
  let(:mainspace_details) { { article_title: 'Selfie' } }
  let(:evaluate_details) { { article_title: 'User:Ragesoss/Evaluate an Article' } }
  let(:cpm) { create(:user, email: 'cpm@wikiedu.org') }

  before do
    allow(SpecialUsers).to receive(:classroom_program_manager).and_return(cpm)
  end

  context 'when there are few priority AiEditAlerts' do
    before do
      2.times do
        create(:ai_edit_alert, course: course, details: mainspace_details)
      end
      5.times do
        create(:ai_edit_alert, course: course, details: evaluate_details)
      end
    end

    it 'does not create an AiSpikeAlert' do
      subject.create_alerts
      expect(AiSpikeAlert.count).to eq(0)
    end
  end

  context 'when there are many priority AiEditAlerts' do
    before do
      3.times do
        create(:ai_edit_alert, course: course, details: mainspace_details)
      end
      5.times do
        create(:ai_edit_alert, course: course, details: evaluate_details)
      end
    end

    it 'creates an AiSpikeAlert and emails classroom program manager' do
      expect(AlertMailer).to receive(:send_alert_email).and_call_original
      subject.create_alerts
      expect(AiSpikeAlert.count).to eq(1)
      expect(AiSpikeAlert.last.email_sent_at).not_to be_nil
    end
  end

  context 'when checking for recent unresolved alerts' do
    before do
      # Create an unresolved alert to trigger the date comparison query
      AiSpikeAlert.create(course: course, resolved: false, created_at: 5.days.ago, details: {})
      # Create recent AiEditAlerts that would trigger a new alert
      3.times do
        create(:ai_edit_alert, course: course, details: mainspace_details)
      end
    end

    it 'correctly compares created_at with a datetime value, not an integer' do
      # This test will fail with MySQL error "Incorrect DATETIME value: '14'"
      # if RECENT_DAYS (integer) is used instead of RECENT_DAYS.days.ago (datetime)
      expect { subject.create_alerts }.not_to raise_error
      # A recent unresolved alert exists, so no new alert should be created
      expect(AiSpikeAlert.count).to eq(1)
    end
  end

  context 'when checking for old unresolved alerts' do
    before do
      # Create an old unresolved alert (outside the recent window)
      AiSpikeAlert.create(course: course, resolved: false, created_at: 15.days.ago, details: {})
      # Create recent AiEditAlerts that would trigger a new alert
      3.times do
        create(:ai_edit_alert, course: course, details: mainspace_details)
      end
    end

    it 'correctly handles date comparison for old alerts' do
      # This test will fail with MySQL error "Incorrect DATETIME value: '14'"
      # if RECENT_DAYS (integer) is used instead of RECENT_DAYS.days.ago (datetime)
      expect(AlertMailer).to receive(:send_alert_email).and_call_original
      expect { subject.create_alerts }.not_to raise_error
      # Old alert is outside recent window, so a new alert should be created
      expect(AiSpikeAlert.count).to eq(2)
    end
  end
end
