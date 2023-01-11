# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/deleted_timeline_alert_manager"

describe DeletedTimelineAlertManager do
  let(:course) { create(:course) }
  let(:week) { create(:week, course_id: course.id, title: "Week1", created_at: 1.month.ago, updated_at: 5.days.from_now )
               create(:week, course_id: course.id, title: "Week2", created_at: 2.month.ago, updated_at: 15.days.from_now ) }
  let!(:block) { create(:block, week_id: week.id, training_module_ids: [1]) }  
  let(:subject) { described_class.new(course) }
  
  context 'when course is not approved' do
    # let(:approved?) { false }

    it 'does not create an alert' do
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end
  # context 'when course is approved' do
  #   # let(:campaigns?) { true }

  #   it 'create an alert' do
  #     subject.create_alerts
  #     expect(Alert.count).to eq(1)
  #   end
  # end
end