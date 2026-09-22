# frozen_string_literal: true

require 'rails_helper'

describe LtiGradebookLabel do
  let(:course) { create(:course) }
  let(:week) { create(:week, course:, order: 3) }
  # 'bibliography-exercise' is a real module seeded into the CI test DB, so reuse
  # it when present rather than creating a duplicate slug (uniqueness violation).
  let(:mapped_exercise) do
    TrainingModule.find_by(slug: 'bibliography-exercise') ||
      create(:training_module, slug: 'bibliography-exercise',
                               name: 'Building your bibliography', kind: 1)
  end

  it 'uses the operator short label for a mapped exercise, with the week prefix' do
    block = create(:block, week:, title: 'A long timeline block title',
                           training_module_ids: [mapped_exercise.id])
    expect(described_class.for_block(block)).to eq('Wk3 Bibliography')
  end

  it 'falls back to the full block title for an unmapped exercise' do
    exercise = create(:training_module, slug: 'some-custom-exercise', name: 'Custom', kind: 1)
    block = create(:block, week:, title: 'Do the custom thing',
                           training_module_ids: [exercise.id])
    expect(described_class.for_block(block)).to eq('Wk3 Do the custom thing')
  end

  it 'falls back to the block title for a training-only block' do
    training = create(:training_module, slug: 'some-custom-training', name: 'Get started', kind: 0)
    block = create(:block, week:, title: 'Get started',
                           training_module_ids: [training.id])
    expect(described_class.for_block(block)).to eq('Wk3 Get started')
  end

  it 'omits the week prefix when the block has no week' do
    block = create(:block, week: nil, title: 'Untimed', training_module_ids: [mapped_exercise.id])
    expect(described_class.for_block(block)).to eq('Bibliography')
  end

  # This used to cut by *byte* (`byteslice(0, 64)`), which on multibyte titles
  # could split a character — yielding a string MySQL rejects with "Incorrect
  # string value" when the discovered line item is saved — and cut a CJK title to
  # roughly 21 characters. Non-Latin timelines are ordinary on the P&E Dashboard.
  describe 'the 64-character AGS limit' do
    def label_for(title)
      exercise = create(:training_module, slug: "ex-#{SecureRandom.hex(4)}",
                                          name: 'Custom', kind: 1)
      described_class.for_block(
        create(:block, week:, title:, training_module_ids: [exercise.id])
      )
    end

    it 'keeps a long title within the limit' do
      expect(label_for('Evaluate an article ' * 10).length).to be <= 64
    end

    it 'leaves a multibyte title valid UTF-8' do
      label = label_for('ウィキペディアの記事を評価する' * 8)
      expect(label).to be_valid_encoding
      expect(label.length).to be <= 64
    end

    # 64 characters, not 64 bytes: the old byte cut lost two thirds of a CJK title.
    it 'counts characters rather than bytes for a multibyte title' do
      expect(label_for('評価' * 40).length).to be > 21
    end

    it 'leaves a short title untouched' do
      expect(label_for('Short one')).to eq('Wk3 Short one')
    end
  end
end
