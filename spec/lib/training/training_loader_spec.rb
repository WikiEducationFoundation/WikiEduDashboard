# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training/training_loader"
require "#{Rails.root}/lib/training_slide"

describe TrainingLoader do
  describe '#load_content' do
    before do
      allow(Features).to receive(:wiki_trainings?).and_return(true)
    end

    let(:subject) do
      TrainingLoader.new(content_class: content_class,
                         path_to_yaml: "#{Rails.root}/training_content/none/*.yml",
                         trim_id_from_filename: false,
                         wiki_base_page: wiki_base_page)
    end

    describe 'for basic slides' do
      let(:content_class) { TrainingSlide }
      let(:wiki_base_page) { 'Training modules/dashboard/slides-test' }

      it 'returns an array of training content' do
        VCR.use_cassette 'training/load_from_wiki' do
          slides = subject.load_content
          expect(slides.first.content).not_to be_empty
        end
      end
    end

    describe 'for invalid content' do
      let(:content_class) { TrainingLibrary }
      let(:wiki_base_page) { 'Training modules/dashboard/libraries-invalid' }
      it 'logs a message and does not return the invalid content' do
        VCR.use_cassette 'training/load_from_wiki' do
          expect(Raven).to receive(:capture_message).at_least(:once)
          libraries = subject.load_content
          expect(libraries.count).to eq(0)
        end
      end
    end

    describe 'for invalid base pages' do
      let(:content_class) { TrainingLibrary }
      let(:wiki_base_page) { 'Training modules/dashboard/does-not-exist' }
      it 'returns an empty collection' do
        VCR.use_cassette 'training/load_from_wiki' do
          modules = subject.load_content
          expect(modules.count).to eq(0)
        end
      end
    end

    describe 'for slides with translations' do
      let(:content_class) { TrainingSlide }
      let(:wiki_base_page) { 'Training modules/dashboard/slides-example' }
      it 'imports slides with translated content' do
        VCR.use_cassette 'training/load_from_wiki' do
          slides = subject.load_content
          spanish = slides.first.translations.es
          expect(spanish).not_to be_empty
        end
      end
    end

    describe 'for modules' do
      let(:content_class) { TrainingModule }
      let(:wiki_base_page) { 'Training modules/dashboard/modules-test' }

      it 'returns an array of training content' do
        VCR.use_cassette 'training/load_from_wiki' do
          modules = subject.load_content
          expect(modules.first.slug).not_to be_empty
        end
      end
    end

    describe 'for libraries' do
      let(:content_class) { TrainingLibrary }
      let(:wiki_base_page) { 'Training modules/dashboard/libraries-test' }

      it 'returns an array of training content' do
        VCR.use_cassette 'training/load_from_wiki' do
          libraries = subject.load_content
          expect(libraries.first.slug).not_to be_empty
        end
      end
    end
  end
end
