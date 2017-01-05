# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/training/training_base"
require "#{Rails.root}/lib/training_module"

describe TrainingBase do
  describe '.load' do
    context 'when a file is misformatted' do
      let(:subject) do
        TrainingBase.load(path_to_yaml: "#{Rails.root}/spec/support/bad_yaml_file.yml",
                          cache_key: 'test')
      end
      it 'raises an error and outputs the filename the bad file' do
        expect(STDOUT).to receive(:puts).with(/.*bad_yaml_file.*/)
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'when there are duplicate slugs' do
      let(:subject) do
        TrainingBase.load(path_to_yaml: "#{Rails.root}/spec/support/duplicate_yaml_slugs/*.yml",
                          cache_key: 'test',
                          trim_id_from_filename: true)
      end
      it 'raises an error noting the duplicate slug name' do
        expect { subject }.to raise_error(TrainingBase::DuplicateSlugError, /.*duplicate-yaml-slug.*/)
      end
    end

    context 'when there are duplicate ids' do
      let(:subject) do
        TrainingBase.load(path_to_yaml: "#{Rails.root}/spec/support/duplicate_yaml_ids/*.yml",
                          cache_key: 'test',
                          trim_id_from_filename: true)
      end
      it 'raises an error noting the duplicate id' do
        expect { subject }.to raise_error(TrainingBase::DuplicateIdError)
      end
    end

    context 'when training_path is set' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('training_path').and_return('training_content/generic')
      end
      it 'loads trainings from that path' do
        TrainingSlide.load
        expect(TrainingSlide.all).not_to be_empty
      end
    end

    context 'when training_path not is set' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('training_path').and_return(nil)
      end
      it 'loads trainings from the default path' do
        TrainingSlide.load
        expect(TrainingSlide.all).not_to be_empty
      end
    end
  end

  describe '.all' do
    it 'loads from yaml files if data is not in cache' do
      Rails.cache.clear
      expect(TrainingLibrary.all).not_to be_empty
      expect(TrainingModule.all).not_to be_empty
      expect(TrainingSlide.all).not_to be_empty
    end
  end
end
