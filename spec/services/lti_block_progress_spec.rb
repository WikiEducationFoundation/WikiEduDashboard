# frozen_string_literal: true

require 'rails_helper'

describe LtiBlockProgress do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:week) { create(:week, course: course, order: 1) }

  let(:training_module) do
    create(:training_module, slug: 'tr-1', name: 'Training One', kind: 0)
  end
  let(:exercise_module) do
    create(:training_module, slug: 'ex-1', name: 'Bibliography exercise',
                             kind: 1, settings: { 'sandbox_location' => 'sandbox/Bibliography' })
  end

  before { allow(LtiLineItemSyncWorker).to receive(:perform_in) }

  describe 'a block with a single training module' do
    let(:block) do
      create(:block, week: week, order: 0, title: 'Get started',
                     training_module_ids: [training_module.id])
    end

    it 'is 0.0 when the user has no completion record' do
      progress = described_class.new(block, user)
      expect(progress.score_given).to eq(0.0)
      expect(progress.gradable?).to be(true)
    end

    it 'is 0.0 when the training is started but not completed' do
      TrainingModulesUsers.create!(user: user, training_module: training_module,
                                   last_slide_completed: 'slide-1')
      expect(described_class.new(block, user).score_given).to eq(0.0)
    end

    it 'is 1.0 when the training is completed' do
      TrainingModulesUsers.create!(user: user, training_module: training_module,
                                   completed_at: 2.days.ago)
      progress = described_class.new(block, user)
      expect(progress.score_given).to eq(1.0)
    end
  end

  describe 'a block with an exercise module' do
    let(:block) do
      create(:block, week: week, order: 1, title: 'Find sources',
                     training_module_ids: [exercise_module.id],
                     due_date: 7.days.ago.to_date)
    end

    it 'is 0.0 when the exercise is not marked complete' do
      TrainingModulesUsers.create!(user: user, training_module: exercise_module)
      expect(described_class.new(block, user).score_given).to eq(0.0)
    end

    it 'is 1.0 when the exercise is marked complete and includes sandbox URL in comment' do
      tmu = TrainingModulesUsers.new(user: user, training_module: exercise_module,
                                     completed_at: 2.days.ago)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
      progress = described_class.new(block, user)
      expect(progress.score_given).to eq(1.0)
      expect(progress.comment).to include('Bibliography exercise:')
      expect(progress.comment).to include('en.wikipedia.org')
      expect(progress.comment).to include('sandbox/Bibliography')
    end

    it 'prefixes [Late] in the comment when completed past due_date' do
      tmu = TrainingModulesUsers.new(user: user, training_module: exercise_module,
                                     completed_at: 1.day.ago)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
      progress = described_class.new(block, user)
      expect(progress.comment).to start_with('[Late]')
    end
  end

  describe 'a block with mixed modules' do
    let(:block) do
      create(:block, week: week, order: 2, title: 'Mixed block',
                     training_module_ids: [training_module.id, exercise_module.id])
    end

    it 'is 1.0 only when all modules are complete' do
      # Training done, exercise not.
      TrainingModulesUsers.create!(user: user, training_module: training_module,
                                   completed_at: 1.day.ago)
      TrainingModulesUsers.create!(user: user, training_module: exercise_module)
      expect(described_class.new(block, user).score_given).to eq(0.0)

      # Both done.
      tmu = TrainingModulesUsers.find_by(user: user, training_module: exercise_module)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
      expect(described_class.new(block, user).score_given).to eq(1.0)
    end

    context 'in exercises_only mode (the lumped per-block exercise column)' do
      it 'is 1.0 when the exercise is marked complete even with untouched trainings' do
        tmu = TrainingModulesUsers.new(user: user, training_module: exercise_module)
        tmu.flags = { course.id => { marked_complete: true } }
        tmu.save!
        progress = described_class.new(block, user, exercises_only: true)
        expect(progress.score_given).to eq(1.0)
        expect(progress.comment).to include('Bibliography exercise:')
        expect(progress.comment).to include('sandbox/Bibliography')
      end

      it 'is 0.0 when the exercise is not marked complete even if trainings are done' do
        TrainingModulesUsers.create!(user: user, training_module: training_module,
                                     completed_at: 1.day.ago)
        TrainingModulesUsers.create!(user: user, training_module: exercise_module)
        expect(described_class.new(block, user, exercises_only: true).score_given).to eq(0.0)
      end
    end
  end

  describe 'signature stability' do
    let(:block) do
      create(:block, week: week, order: 0, title: 'Get started',
                     training_module_ids: [training_module.id])
    end

    it 'is the same SHA1 hash for two equivalent computations' do
      first = described_class.new(block, user).signature
      second = described_class.new(block, user).signature
      expect(first).to eq(second)
    end

    it 'changes when score changes' do
      before_sig = described_class.new(block, user).signature
      TrainingModulesUsers.create!(user: user, training_module: training_module,
                                   completed_at: 1.day.ago)
      after_sig = described_class.new(block, user).signature
      expect(after_sig).not_to eq(before_sig)
    end
  end

  describe 'an empty (no-modules) block' do
    let(:block) do
      create(:block, week: week, order: 0, title: 'Empty', training_module_ids: [])
    end

    it 'is not gradable' do
      expect(described_class.new(block, user).gradable?).to be(false)
    end
  end
end
