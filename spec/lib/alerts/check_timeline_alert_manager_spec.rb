# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/check_timeline_alert_manager"

describe CheckTimelineAlertManager do
  let(:course) { create(:course) }
  let(:week) do
    create(:week, course_id: course.id, title: 'Week1', created_at: 1.month.ago,
updated_at: 5.days.from_now)
    create(:week, course_id: course.id, title: 'Week2', created_at: 1.month.ago,
updated_at: 5.days.from_now)
  end
  let(:course_approved) do
    course.campaigns << Campaign.first
  end
  let(:adding_blocks_without_training_module) do
    create(:block, week_id: week.id)
  end
  let(:adding_blocks_with_training_module) do
    create(:block, week_id: week.id, training_module_ids: [1])
  end
  let(:subject) do
    described_class.new(course)
  end

  context 'when course is not approved' do
    it 'does not create an alert' do
      adding_blocks_without_training_module
      subject
      expect(CheckTimelineAlert.count).to eq(0)
    end
  end

  context 'when course is approved but has 0 training modules' do
    it 'create an alert' do
      adding_blocks_without_training_module
      course_approved
      subject
      expect(CheckTimelineAlert.count).to eq(1)
    end
  end

  context 'when course is approved but has training modules' do
    it 'does not create an alert' do
      adding_blocks_with_training_module
      course_approved
      subject
      expect(CheckTimelineAlert.count).to eq(0)
    end
  end
end
