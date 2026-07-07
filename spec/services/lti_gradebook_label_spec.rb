# frozen_string_literal: true

require 'rails_helper'

describe LtiGradebookLabel do
  let(:course) { create(:course) }
  let(:week) { create(:week, course:, order: 3) }

  it 'uses the operator short label for a mapped exercise, with the week prefix' do
    exercise = create(:training_module, slug: 'bibliography-exercise',
                                        name: 'Building your bibliography', kind: 1)
    block = create(:block, week:, title: 'A long timeline block title',
                           training_module_ids: [exercise.id])
    expect(described_class.for_block(block)).to eq('Wk3 Bibliography')
  end

  it 'falls back to the full block title for an unmapped exercise' do
    exercise = create(:training_module, slug: 'some-custom-exercise', name: 'Custom', kind: 1)
    block = create(:block, week:, title: 'Do the custom thing',
                           training_module_ids: [exercise.id])
    expect(described_class.for_block(block)).to eq('Wk3 Do the custom thing')
  end

  it 'falls back to the block title for a training-only block' do
    training = create(:training_module, slug: 'get-started', name: 'Get started', kind: 0)
    block = create(:block, week:, title: 'Get started',
                           training_module_ids: [training.id])
    expect(described_class.for_block(block)).to eq('Wk3 Get started')
  end

  it 'omits the week prefix when the block has no week' do
    exercise = create(:training_module, slug: 'bibliography-exercise', name: 'Bib', kind: 1)
    block = create(:block, week: nil, title: 'Untimed', training_module_ids: [exercise.id])
    expect(described_class.for_block(block)).to eq('Bibliography')
  end
end
