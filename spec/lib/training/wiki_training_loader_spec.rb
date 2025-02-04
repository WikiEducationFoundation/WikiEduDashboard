# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training/wiki_training_loader"

describe WikiTrainingLoader do
  before do
    TrainingModule.destroy_all
    TrainingSlide.destroy_all
    TrainingLibrary.destroy_all
  end

  describe '#load_content' do
    before do
      allow(Features).to receive(:wiki_trainings?).and_return(true)
    end

    let(:subject) do
      described_class.new(content_class:, slug_list:)
    end
    let(:slug_list) { nil }

    describe 'for basic slides' do
      let(:content_class) { TrainingSlide }

      before do
        allow(content_class).to receive(:wiki_base_page)
          .and_return('Training modules/dashboard/slides-test')
      end

      context 'with no slug list' do
        it 'returns an array of training content' do
          VCR.use_cassette 'cached/training/load_from_wiki' do
            slides = subject.load_content
            expect(slides.first.content).not_to be_empty
          end
        end
      end

      context 'with a good slug list' do
        # This slug needs to be linked on Meta:
        # https://meta.wikimedia.org/wiki/Training_modules/dashboard/slides-test
        let(:slug_list) { ['using-media'] }

        it 'returns an array of just the content from the slug list' do
          VCR.use_cassette 'cached/training/load_from_wiki' do
            slides = subject.load_content
            expect(slides.count).to eq(1)
            expect(slides.first.slug).to eq('using-media')
          end
        end
      end

      context 'with a bad slug list' do
        let(:slug_list) { ['this-is-not-a-slug-listed-on-meta'] }

        it 'raises an error' do
          VCR.use_cassette 'cached/training/load_from_wiki' do
            expect { subject.load_content }
              .to raise_error(WikiTrainingLoader::NoMatchingWikiPagesFound)
          end
        end
      end
    end

    describe 'for invalid content' do
      let(:content_class) { TrainingLibrary }

      before do
        allow(content_class).to receive(:wiki_base_page)
          .and_return('Training modules/dashboard/libraries-invalid')
      end

      it 'logs a message and does not return the invalid content' do
        VCR.use_cassette 'cached/training/load_from_wiki' do
          expect(Sentry).to receive(:capture_message).at_least(:once)
          libraries = subject.load_content
          expect(libraries.count).to eq(0)
        end
      end
    end

    describe 'for invalid base pages' do
      let(:content_class) { TrainingLibrary }

      before do
        allow(content_class).to receive(:wiki_base_page)
          .and_return('Training modules/dashboard/does-not-exist')
      end

      it 'returns an empty collection' do
        VCR.use_cassette 'cached/training/load_from_wiki' do
          modules = subject.load_content
          expect(modules.count).to eq(0)
        end
      end
    end

    describe 'for slides with translations' do
      let(:content_class) { TrainingSlide }

      before do
        allow(content_class).to receive(:wiki_base_page)
          .and_return('Training modules/dashboard/slides-example')
      end

      it 'imports slides with translated content' do
        VCR.use_cassette 'cached/training/load_from_wiki' do
          slides = subject.load_content
          spanish = slides.first.translations['es']
          expect(spanish).not_to be_empty
        end
      end
    end

    describe 'for modules' do
      let(:content_class) { TrainingModule }

      before do
        allow(content_class).to receive(:wiki_base_page)
          .and_return('Training modules/dashboard/modules-test')
      end

      it 'returns an array of training content' do
        VCR.use_cassette 'cached/training/load_from_wiki' do
          modules = subject.load_content
          expect(modules.first.slug).not_to be_empty
        end
      end
    end

    describe 'for libraries (en)' do
      let(:content_class) { TrainingLibrary }

      before do
        allow(content_class).to receive(:wiki_base_page)
          .and_return('Training modules/dashboard/libraries-test')
      end

      it 'returns an array of training content' do
        VCR.use_cassette 'cached/training/load_from_wiki' do
          libraries = subject.load_content
          expect(libraries.first.slug).not_to be_empty
        end
      end
    end

    describe 'for libraries (de)' do
      let(:content_class) { TrainingLibrary }

      before do
        allow(content_class).to receive(:wiki_base_page)
          .and_return('Training modules/dashboard/libraries-dev')
      end

      it 'loads translated content' do
        VCR.use_cassette 'cached/training/load_from_wiki' do
          content_class.load
          # https://meta.wikimedia.org/wiki/User:Ragesoss/dashboard_libraries/editing-wikipedia-dev.json
          expect(content_class.find(10002).translations.key?('de')).to eq(true)
        end
      end
    end
  end
end
