# frozen_string_literal: true

require 'rails_helper'

describe LtiTrainingProgress do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:week) { create(:week, course: course, order: 1) }

  let(:training_a) { create(:training_module, slug: 'tr-a', name: 'A', kind: 0) }
  let(:training_b) { create(:training_module, slug: 'tr-b', name: 'B', kind: 0) }
  let(:exercise) { create(:training_module, slug: 'ex-1', name: 'Exercise', kind: 1) }

  before do
    allow(LtiLineItemSyncWorker).to receive(:perform_in)
    create(:block, week: week, order: 0, title: 'B1',
                   training_module_ids: [training_a.id, exercise.id])
    create(:block, week: week, order: 1, title: 'B2',
                   training_module_ids: [training_b.id])
  end

  it 'aggregates training-kind module completions, ignoring exercises' do
    TrainingModulesUsers.create!(user: user, training_module: training_a,
                                 completed_at: 2.days.ago)
    progress = described_class.new(course, user)

    expect(progress.score_given).to be_within(0.0001).of(0.5) # 1 of 2 trainings
    expect(progress.score_maximum).to eq(1.0)
    expect(progress.comment).to include('1 of 2 trainings completed')
  end

  it 'is 0.0 when no trainings are completed' do
    progress = described_class.new(course, user)
    expect(progress.score_given).to eq(0.0)
  end

  it 'is 1.0 when all trainings are complete' do
    TrainingModulesUsers.create!(user: user, training_module: training_a,
                                 completed_at: 2.days.ago)
    TrainingModulesUsers.create!(user: user, training_module: training_b,
                                 completed_at: 1.day.ago)
    expect(described_class.new(course, user).score_given).to eq(1.0)
  end

  it 'is not gradable when course has no training-kind modules' do
    course2 = create(:course, slug: 'no-tr/course')
    week2 = create(:week, course: course2, order: 1)
    create(:block, week: week2, order: 0, title: 'Only exercises',
                   training_module_ids: [exercise.id])

    expect(described_class.new(course2, user).gradable?).to be(false)
  end
end
