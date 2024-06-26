# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/workers/training_base_worker"

RSpec.describe TrainingBaseWorker, type: :worker do
  describe '#perform' do
    context 'when updating all modules' do
      it 'performs load_all' do
        allow(TrainingLibrary).to receive(:load_async)
        allow(TrainingModule).to receive(:load_async)
        allow(TrainingBase).to receive(:update_error)

        expect_any_instance_of(described_class).to receive(:perform_load_all)

        described_class.new.perform('slug' => 'all')

        expect(TrainingLibrary).to have_received(:load_async)
        expect(TrainingModule).to have_received(:load_async)
        expect(TrainingBase).not_to have_received(:update_error)
      end
    end

    context 'when reloading a single module' do
      let(:slug) { 'your_module_slug' }
      let(:training_module) { create(:training_module, slug:) }

      before do
        allow(TrainingLibrary).to receive(:load_async)
        allow(TrainingModule).to receive(:load_async)
        allow(TrainingBase).to receive(:update_error)
        allow(TrainingModule).to receive(:find_by).with(slug:).and_return(training_module)
      end

      it 'performs reload_module' do
        expect_any_instance_of(described_class).to receive(:perform_reload_module).with(slug)

        described_class.new.perform(slug)

        expect(TrainingLibrary).to have_received(:load_async)
        expect(TrainingModule).to have_received(:load_async)
        expect(TrainingBase).not_to have_received(:update_error)
      end
    end

    context 'when reloading a non-existent module' do
      let(:non_existent_slug) { 'non_existent_slug' }

      before do
        allow(TrainingLibrary).to receive(:load_async)
        allow(TrainingModule).to receive(:load_async)
      end

      it 'updates error' do
        allow(TrainingModule).to receive(:find_by).with(slug: non_existent_slug).and_return(nil)

        expect(TrainingBase).to receive(:update_error).with(
          /No module #{non_existent_slug} found!/, TrainingModule
        )

        described_class.new.perform(non_existent_slug)

        expect(TrainingLibrary).to have_received(:load_async)
        expect(TrainingModule).to have_received(:load_async)
      end
    end
  end
end
