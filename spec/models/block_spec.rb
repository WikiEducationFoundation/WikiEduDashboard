# frozen_string_literal: true

require 'rails_helper'

describe Block do
  describe '#training_modules' do
    let(:first_module) do
      create(:training_module, id: 1001, slug: 'first-module', name: 'First')
    end
    let(:second_module) do
      create(:training_module, id: 1002, slug: 'second-module', name: 'Second')
    end
    let(:course) { create(:course) }
    let(:week) { create(:week, course:) }
    let(:block) do
      create(:block, week:, training_module_ids: [second_module.id, first_module.id])
    end

    it 'returns modules in the order they were assigned to the block' do
      expect(block.training_modules.map(&:id)).to eq([second_module.id, first_module.id])
    end

    it 'skips ids that no longer correspond to a module' do
      block.update(training_module_ids: [second_module.id, 999_999, first_module.id])
      expect(block.reload.training_modules.map(&:id)).to eq([second_module.id, first_module.id])
    end
  end
end
