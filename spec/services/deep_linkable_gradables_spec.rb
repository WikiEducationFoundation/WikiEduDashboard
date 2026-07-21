# frozen_string_literal: true

require 'rails_helper'

describe DeepLinkableGradables do
  let(:course) { create(:course) }
  let!(:week) { create(:week, course:, order: 1) }
  let(:training_module) do
    create(:training_module, slug: 'get-started', name: 'Get started', kind: 0)
  end
  let(:exercise_module) do
    create(:training_module, slug: 'bibliography', name: 'Bibliography', kind: 1)
  end

  before do
    # Block.after_commit would queue the sync worker; stub so the synchronous
    # Sidekiq runner doesn't fire during setup.
    allow(LtiLineItemSyncWorker).to receive(:perform_in)
    allow(LtiLineItemSyncWorker).to receive(:perform_async)
  end

  subject(:gradables) { described_class.new(course).result }

  context 'with a training-only block and an exercise block' do
    let!(:training_block) do
      create(:block, week:, order: 0, title: 'Get started on Wikipedia',
                     training_module_ids: [training_module.id])
    end
    let!(:exercise_block) do
      create(:block, week:, order: 1, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end

    it 'offers one option per exercise block, keyed Block:<id>' do
      exercise = gradables.find { |g| g.gradable_type == 'Block' }
      expect(exercise.gradable_id).to eq(exercise_block.id)
      expect(exercise.resource).to eq("Block:#{exercise_block.id}")
      expect(exercise.label).to eq('Wk1 Find sources')
    end

    it 'offers a single TrainingProgress rollup option' do
      rollup = gradables.select { |g| g.gradable_type == LtiLineItem::TRAINING_PROGRESS_TYPE }
      expect(rollup.length).to eq(1)
      expect(rollup.first.resource).to eq('TrainingProgress')
      expect(rollup.first.gradable_id).to be_nil
    end

    it 'does not offer a training-only block as its own exercise option' do
      block_ids = gradables.select { |g| g.gradable_type == 'Block' }.map(&:gradable_id)
      expect(block_ids).not_to include(training_block.id)
    end
  end

  context 'with exercise blocks created out of timeline order' do
    let!(:week2) { create(:week, course:, order: 2) }
    # Insertion order deliberately reversed: the week-2 block gets the
    # lower id, so default (id) ordering would list it first.
    let!(:later_block) do
      create(:block, week: week2, order: 0, title: 'Later exercise',
                     training_module_ids: [exercise_module.id])
    end
    let!(:early_block) do
      create(:block, week:, order: 0, title: 'Early exercise',
                     training_module_ids: [exercise_module.id])
    end

    it 'lists options in timeline order, not insertion order' do
      block_ids = gradables.select { |g| g.gradable_type == 'Block' }.map(&:gradable_id)
      expect(block_ids).to eq([early_block.id, later_block.id])
    end
  end

  context 'when the course has exercises but no training modules' do
    let!(:exercise_block) do
      create(:block, week:, order: 0, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end

    it 'omits the TrainingProgress rollup' do
      expect(gradables.map(&:gradable_type)).not_to include(LtiLineItem::TRAINING_PROGRESS_TYPE)
    end
  end

  context 'with no gradable blocks at all' do
    let!(:plain_block) do
      create(:block, week:, order: 0, title: 'Read this', training_module_ids: [])
    end

    it 'returns an empty list' do
      expect(gradables).to be_empty
    end
  end
end
