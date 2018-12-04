# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training_library"

describe TrainingBase do
  before do
    allow(Features).to receive(:wiki_trainings?).and_return(false)
  end

  after(:all) do
    TrainingLibrary.flush
  end

  describe 'abstract parent class' do
    it 'raises errors for required template instance methods' do
      subject = described_class.inflate({}, 'foo')
      expect { subject.valid? }.to raise_error(NotImplementedError)
    end

    it 'raises errors for required template class methods' do
      expect { described_class.cache_key }.to raise_error(NotImplementedError)
    end
  end

  describe '.load' do
    let(:subject) { TrainingModule.load }

    context 'when a module file is misformatted' do
      before do
        allow(described_class).to receive(:base_path)
          .and_return("#{Rails.root}/spec/support/bad_yaml")
      end

      it 'raises an error and outputs the filename the bad file' do
        expect(STDOUT).to receive(:puts).with(/.*bad_yaml_file.*/)
        expect { subject }.to raise_error(TypeError)
      end
    end

    context 'when a slide file is misformatted' do
      let(:subject) { TrainingSlide.load }

      before do
        allow(described_class).to receive(:base_path)
          .and_return("#{Rails.root}/spec/support/bad_yaml_slide")
      end

      it 'raises an error that includes the filename of the bad file' do
        expect { subject }.to raise_error(YamlTrainingLoader::InvalidYamlError,
                                          /.*bad_yaml_slide.*/)
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
    context 'when the cache is empty' do
      before do
        TrainingLibrary.flush
      end

      it 'loads from yaml files' do
        expect(TrainingLibrary.all).not_to be_empty
      end
    end
  end

  describe '.load_all' do
    context 'with wiki trainings disabled' do
      before do
        allow(Features).to receive(:wiki_trainings?).and_return(false)
      end

      it 'sets wiki_slide to nil for training content' do
        described_class.load_all
        expect(TrainingLibrary.all.last.wiki_page).to be_nil
        expect(TrainingModule.all.last.wiki_page).to be_nil
        expect(TrainingSlide.last.wiki_page).to be_nil
      end
    end

    context 'with wiki trainings enabled' do
      before do
        TrainingSlide.destroy_all
        TrainingModule.destroy_all
        allow(Features).to receive(:wiki_trainings?).and_return(true)
      end

      it 'loads libraries, modules and slides that include the source wiki_page' do
        VCR.use_cassette 'wiki_trainings' do
          described_class.load_all
        end
        TrainingLibrary.all.each do |library|
          expect(library.wiki_page).to match(%r{/dashboard libraries/.*json})
        end
        TrainingModule.all.each do |training_module|
          expect(training_module.wiki_page).to match(%r{User:.*/.*.json})
        end
        TrainingSlide.all.each do |slide|
          expect(slide.wiki_page).to match(%r{Training modules/dashboard/slides/.+})
        end
      end
    end
  end

  # Make sure default trainings get reloaded
end
