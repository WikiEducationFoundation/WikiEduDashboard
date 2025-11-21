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
end
