# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/training_update"

describe TrainingUpdate do
  let(:subject) { described_class.new(module_slug: 'all').result }

  context 'when updates are paused' do
    before do
      allow_any_instance_of(described_class).to receive(:updates_paused?).and_return(true)
    end
    it 'returns with a relevant message' do
      expect(subject).to match(/Updates are currently paused/)
    end
  end

  context 'when another training update is running' do
    before do
      allow_any_instance_of(described_class).to receive(:update_running?).and_return(true)
    end
    it 'returns with a relevant message' do
      expect(subject).to match(/Try again later/)
    end
  end
end
