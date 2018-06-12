# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training_library"
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
    let(:subject) { TrainingModule.load }

    context 'when a module file is misformatted' do
      before do
        allow(TrainingBase).to receive(:base_path)
          .and_return("#{Rails.root}/spec/support/bad_yaml")
      end

      it 'raises an error and outputs the filename the bad file' do
        expect(STDOUT).to receive(:puts).with(/.*bad_yaml_file.*/)
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'when a slide file is misformatted' do
      let(:subject) { TrainingSlide.load }
      before do
        allow(TrainingBase).to receive(:base_path)
          .and_return("#{Rails.root}/spec/support/bad_yaml_slide")
      end

      it 'raises an error that includes the filename of the bad file' do
        expect { subject }.to raise_error(TrainingLoader::InvalidYamlError,
                                          /.*bad_yaml_slide.*/)
      end
    end

    context 'when there are duplicate slugs' do
      before do
        allow(TrainingModule).to receive(:trim_id_from_filename).and_return(true)
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
    context 'when the cache is empty' do
      before(:each) do
        TrainingLibrary.flush
        TrainingModule.flush
      end

      it 'loads from yaml files' do
        expect(TrainingLibrary.all).not_to be_empty
        expect(TrainingModule.all).not_to be_empty
      end
    end
  end

  describe '.load_all' do
    context 'with wiki trainings disabled' do
      before do
        allow(Features).to receive(:wiki_trainings?).and_return(false)
      end
      it 'runs without error with wiki' do
        TrainingBase.load_all
      end
    end

    context 'with wiki trainings enabled' do
      before do
        allow(Features).to receive(:wiki_trainings?).and_return(true)
      end
      it 'runs without error with wiki' do
        VCR.use_cassette 'wiki_trainings' do
          TrainingBase.load_all
        end
      end
    end
  end

  # Make sure default trainings get reloaded
  after(:all) do
    TrainingModule.flush
    TrainingLibrary.flush
  end
end
