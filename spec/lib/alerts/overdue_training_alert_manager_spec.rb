# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/alerts/overdue_training_alert_manager')

describe OverdueTrainingAlertManager do
  let(:subject) { described_class.new([course]).create_alerts }
  let(:course) { create(:course, start: start_date) }
  let(:start_date) { '2018-06-07'.to_date }
  let(:week) { create(:week) }
  let(:block) { create(:block, training_module_ids: [1, 2, 3], due_date:) }
  let(:due_date) { nil }
  let(:exercise_week) { create(:week) }
  let(:exercise_block) { create(:block, training_module_ids: [38], due_date: exercise_due_date) }
  let(:exercise_due_date) { 1.day.from_now }
  let(:user) { create(:user, email: 'student@example.edu') }

  before do
    TrainingModule.load_all
    create(:courses_user, user:, course:)
    allow(Features).to receive(:email?).and_return(true)
    course.weeks << [week, exercise_week]
    week.blocks << block
    exercise_week.blocks << exercise_block
  end

  context 'when training is overdue' do
    let(:due_date) { 1.day.ago }

    it 'creates an alert' do
      expect(OverdueTrainingAlert.count).to eq(0)
      subject
      expect(OverdueTrainingAlert.count).to eq(1)
    end

    it 'handles invalid email errors gracefully' do
      expect_any_instance_of(ActionMailer::MessageDelivery)
        .to receive(:deliver_now).and_raise(Mailgun::CommunicationError)
      expect(Sentry).to receive(:capture_exception)
      subject
    end
  end

  context 'when training is not actually a training' do
    let(:exercise_due_date) { 1.day.ago }
    let(:due_date) { 1.day.from_now }

    it 'does not create an alert' do
      expect(OverdueTrainingAlert.count).to eq(0)
      subject
      expect(OverdueTrainingAlert.count).to eq(0)
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
      create(:overdue_training_alert, user:, course:, created_at: 5.days.ago)
      expect(OverdueTrainingAlert.count).to eq(1)
      subject
      expect(OverdueTrainingAlert.count).to eq(1)
    end
  end

  context 'when training is overdue and an 10-plus day old alert exists' do
    let(:due_date) { 11.days.ago }

    it 'creates another alert' do
      create(:overdue_training_alert, user:, course:, created_at: 11.days.ago)
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
