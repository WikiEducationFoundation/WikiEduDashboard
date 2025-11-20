# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/course_ai_alert_manager"

describe CourseAiAlertManager do
  let(:course) { create(:course) }
  let(:subject) { described_class.new([course]) }
  let(:mainspace_details) { { article_title: 'Selfie' } }
  let(:evaluate_details) { { article_title: 'User:Ragesoss/Evaluate an Article' } }

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

    it 'creates an AiSpikeAlert' do
      subject.create_alerts
      expect(AiSpikeAlert.count).to eq(1)
    end
  end
end
