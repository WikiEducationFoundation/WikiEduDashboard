# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training/training_base"
require "#{Rails.root}/lib/training_module"

describe TrainingBase do
  before do
    allow(Features).to receive(:wiki_trainings?).and_return(false)
  end

  describe 'abstract parent class' do
    it 'raises errors for required template instance methods' do
      subject = TrainingBase.new({}, 'foo')
      expect { subject.valid? }.to raise_error(NotImplementedError)
    end

    it 'raises errors for required template class methods' do
      expect { described_class.cache_key }.to raise_error(NotImplementedError)
    end
  end

  describe '.load' do
    let(:subject) { TrainingSlide.load }

    context 'when a file is misformatted' do
      before do
        allow(TrainingBase).to receive(:base_path)
          .and_return("#{Rails.root}/spec/support/bad_yaml")
      end

      it 'raises an error and outputs the filename the bad file' do
        expect(STDOUT).to receive(:puts).with(/.*bad_yaml_file.*/)
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'when there are duplicate slugs' do
      before do
        allow(TrainingBase).to receive(:base_path)
          .and_return("#{Rails.root}/spec/support/duplicate_yaml_slugs")
      end

      it 'raises an error noting the duplicate slug name' do
        expect { subject }.to raise_error(TrainingBase::DuplicateSlugError,
                                          /.*duplicate-yaml-slug.*/)
      end
    end

    context 'when there are duplicate ids' do
      before do
        allow(TrainingBase).to receive(:base_path)
          .and_return("#{Rails.root}/spec/support/duplicate_yaml_ids")
      end

      it 'raises an error noting the duplicate id' do
        expect { subject }.to raise_error(TrainingBase::DuplicateIdError)
      end
    end

    context 'when training_path is set' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('training_path').and_return('training_content/wiki_ed')
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

  describe '.load_all' do
    it 'runs without error' do
      TrainingBase.load_all
    end
  end
end
