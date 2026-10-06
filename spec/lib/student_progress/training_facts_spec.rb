# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/student_progress/training_facts"

describe StudentProgress::TrainingFacts do
  let(:course) do
    create(:course, start: '2026-01-05', end: '2026-05-01', timeline_start: '2026-01-05')
  end
  let(:week) { create(:week, course:, order: 0) }
  let(:student) { create(:user) }
  let(:training) do
    create(:training_module, slug: 'tr-a', kind: 0, slide_slugs: %w[one two three four])
  end
  let(:facts) { described_class.new(StudentProgress::Roster.new(course:, user_ids: [student.id])) }

  before { create(:block, week:, order: 0, training_module_ids: [training.id]) }

  def fact
    facts.training_for(student, training)
  end

  it 'reports when a finished module was completed' do
    completed_at = Time.zone.parse('2026-01-07 10:00')
    TrainingModulesUsers.create!(user: student, training_module: training, completed_at:)
    expect(fact).to be_completed
    expect(fact.completed_at).to eq(completed_at)
    expect(fact.slide_progress).to eq(1.0)
  end

  it 'reports slide progress for a module under way' do
    TrainingModulesUsers.create!(user: student, training_module: training,
                                 last_slide_completed: 'two')
    expect(fact).not_to be_completed
    expect(fact.slide_progress).to eq(0.5)
  end

  it 'has no progress for a module not started, or reached via a slide since removed' do
    expect(fact.slide_progress).to be_nil
    TrainingModulesUsers.create!(user: student, training_module: training,
                                 last_slide_completed: 'gone')
    expect(described_class.new(StudentProgress::Roster.new(course:, user_ids: [student.id]))
             .training_for(student, training).slide_progress).to be_nil
  end

  it 'carries the due date and is overdue only once it passes unfinished' do
    due = fact.due_date
    expect(due).to be_present
    travel_to(due + 1.day) { expect(fact).to be_overdue }
    travel_to(due) { expect(fact).not_to be_overdue }
  end

  it 'is not overdue once complete' do
    TrainingModulesUsers.create!(user: student, training_module: training, completed_at: 1.day.ago)
    travel_to(fact.due_date + 1.day) { expect(fact).not_to be_overdue }
  end
end
