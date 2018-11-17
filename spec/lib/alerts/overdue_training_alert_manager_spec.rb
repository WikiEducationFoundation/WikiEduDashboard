# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/overdue_training_alert_manager"

describe OverdueTrainingAlertManager do
  before { TrainingModule.load_all }

  let(:subject) { described_class.new([course]).create_alerts }
  let(:course) { create(:course, start: start_date) }
  let(:start_date) { '2018-06-07'.to_date }
  let(:week) { create(:week) }
  let(:block) { create(:block, training_module_ids: [1, 2, 3], due_date: due_date) }
  let(:due_date) { nil }
  let(:user) { create(:user, email: 'student@example.edu') }

  before do
    create(:courses_user, user: user, course: course)
    course.weeks << week
    week.blocks << block
  end

  context 'when training is overdue' do
    let(:due_date) { 1.day.ago }

    it 'creates an alert' do
      expect(OverdueTrainingAlert.count).to eq(0)
      subject
      expect(OverdueTrainingAlert.count).to eq(1)
    end
  end

  context 'when training is not yet due' do
    let(:due_date) { 1.day.from_now }

    it 'does not create an alert' do
      expect(OverdueTrainingAlert.count).to eq(0)
      subject
      expect(OverdueTrainingAlert.count).to eq(0)
    end
  end

  context 'when training is overdue but a recent alert exists' do
    let(:due_date) { 5.days.ago }

    it 'does not create a new alert' do
      create(:overdue_training_alert, user: user, course: course, created_at: 5.days.ago)
      expect(OverdueTrainingAlert.count).to eq(1)
      subject
      expect(OverdueTrainingAlert.count).to eq(1)
    end
  end

  context 'when training is overdue and an 10-plus day old alert exists' do
    let(:due_date) { 11.days.ago }

    it 'creates another alert' do
      create(:overdue_training_alert, user: user, course: course, created_at: 11.days.ago)
      expect(OverdueTrainingAlert.count).to eq(1)
      subject
      expect(OverdueTrainingAlert.count).to eq(2)
    end
  end

  context 'when the course was already underway before this feature launched' do
    let(:start_date) { '2018-05-01'.to_date }
    let(:due_date) { 1.day.ago }

    it 'does not create an alert' do
      expect(OverdueTrainingAlert.count).to eq(0)
      subject
      expect(OverdueTrainingAlert.count).to eq(0)
    end
  end
end
