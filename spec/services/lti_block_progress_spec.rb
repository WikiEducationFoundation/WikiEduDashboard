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

  # A block's column grades its exercises only — its training-kind modules are
  # graded by the rolled-up "Wikipedia trainings" column, so counting them here
  # too would double-count them and hold the exercise column at 0 until the
  # surrounding trainings happened to be complete.
  describe 'a block with only training modules' do
    let(:block) do
      create(:block, week: week, order: 0, title: 'Get started',
                     training_module_ids: [training_module.id])
    end

    it 'is not gradable — it has no exercise to grade' do
      progress = described_class.new(block, user)
      expect(progress.gradable?).to be(false)
    end

    it 'stays ungradable even once the training is complete' do
      TrainingModulesUsers.create!(user: user, training_module: training_module,
                                   completed_at: 2.days.ago)
      expect(described_class.new(block, user).gradable?).to be(false)
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

    it 'is 1.0 without leaking the sandbox URL or username into the comment' do
      tmu = TrainingModulesUsers.new(user: user, training_module: exercise_module,
                                     completed_at: 2.days.ago)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
      progress = described_class.new(block, user)
      expect(progress.score_given).to eq(1.0)
      expect(progress.comment.to_s).not_to include('sandbox/Bibliography')
      expect(progress.comment.to_s).not_to include('en.wikipedia.org')
      expect(progress.comment.to_s).not_to include('User:')
    end

    # There is no lateness marker any more. It was computed from "score at maximum
    # and the due date has passed", never from a completion time, so once the due
    # date went by every student who finished on time got marked late. An exercise
    # completion records no timestamp (`flags[course_id] = { marked_complete: }`),
    # so the marker isn't computable here at all — and a gradebook comment feeds
    # real grade decisions, so being silent beats being wrong for everyone.
    it 'adds no comment for a completion after the due date' do
      tmu = TrainingModulesUsers.new(user: user, training_module: exercise_module,
                                     completed_at: 1.day.ago)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
      progress = described_class.new(block, user)
      expect(progress.score_given).to eq(1.0)
      expect(progress.comment).to be_nil
    end

    it 'adds no comment for an on-time completion either' do
      block.week.course.update!(start: 1.month.ago)
      tmu = TrainingModulesUsers.new(user: user, training_module: exercise_module,
                                     completed_at: 30.days.ago)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
      expect(described_class.new(block, user).comment).to be_nil
    end
  end

  describe 'a block with mixed modules' do
    let(:block) do
      create(:block, week: week, order: 2, title: 'Mixed block',
                     training_module_ids: [training_module.id, exercise_module.id])
    end

    # The block's training module is ignored here: it's graded by the trainings
    # roll-up column, so the exercise alone decides this column's score.
    it 'is 1.0 once the exercise is complete, whatever the trainings say' do
      TrainingModulesUsers.create!(user: user, training_module: training_module)
      tmu = TrainingModulesUsers.new(user: user, training_module: exercise_module)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
      expect(described_class.new(block, user).score_given).to eq(1.0)
    end

    it 'is 0.0 when the exercise is not marked complete even if trainings are done' do
      TrainingModulesUsers.create!(user: user, training_module: training_module,
                                   completed_at: 1.day.ago)
      TrainingModulesUsers.create!(user: user, training_module: exercise_module)
      expect(described_class.new(block, user).score_given).to eq(0.0)
    end

    it 'keeps the sandbox URL and username out of the comment' do
      tmu = TrainingModulesUsers.new(user: user, training_module: exercise_module)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
      progress = described_class.new(block, user)
      expect(progress.score_given).to eq(1.0)
      expect(progress.comment.to_s).not_to include('sandbox/Bibliography')
      expect(progress.comment.to_s).not_to include('User:')
    end
  end

  describe 'signature stability' do
    let(:block) do
      create(:block, week: week, order: 0, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end

    it 'is the same SHA1 hash for two equivalent computations' do
      first = described_class.new(block, user).signature
      second = described_class.new(block, user).signature
      expect(first).to eq(second)
    end

    it 'changes when score changes' do
      before_sig = described_class.new(block, user).signature
      tmu = TrainingModulesUsers.new(user: user, training_module: exercise_module)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
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
