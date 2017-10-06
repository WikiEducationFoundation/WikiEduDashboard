# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training/training_loader"
require "#{Rails.root}/lib/training_slide"

describe TrainingLoader do
  describe '#load_content' do
    before do
      allow(Features).to receive(:wiki_trainings?).and_return(true)
      no_yaml = "#{Rails.root}/training_content/none/*.yml"
      allow(TrainingSlide).to receive(:path_to_yaml).and_return(no_yaml)
      allow(TrainingModule).to receive(:path_to_yaml).and_return(no_yaml)
      allow(TrainingLibrary).to receive(:path_to_yaml).and_return(no_yaml)
    end

    let(:subject) do
      TrainingLoader.new(content_class: content_class, slug_whitelist: slug_whitelist)
    end
    let(:slug_whitelist) { nil }

    describe 'for basic slides' do
      let(:content_class) { TrainingSlide }
      before do
        allow(content_class).to receive(:wiki_base_page)
          .and_return('Training modules/dashboard/slides-test')
      end

      context 'with no slug whitelist' do
        it 'returns an array of training content' do
          VCR.use_cassette 'training/load_from_wiki' do
            slides = subject.load_content
            expect(slides.first.content).not_to be_empty
          end
        end
      end

      context 'with a good slug whitelist' do
        # This slug needs to be linked on Meta:
        # https://meta.wikimedia.org/wiki/Training_modules/dashboard/slides-test
        let(:slug_whitelist) { ['using-media'] }
        it 'returns an array of just the whitelisted content' do
          VCR.use_cassette 'training/load_from_wiki' do
            slides = subject.load_content
            expect(slides.count).to eq(1)
            expect(slides.first.slug).to eq('using-media')
          end
        end
      end

      context 'with a bad slug whitelist' do
        let(:slug_whitelist) { ['this-is-not-a-slug-listed-on-meta'] }
        it 'raises an error' do
          VCR.use_cassette 'training/load_from_wiki' do
            expect { subject.load_content }.to raise_error(TrainingLoader::NoMatchingWikiPagesFound)
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
        VCR.use_cassette 'training/load_from_wiki' do
          expect(Raven).to receive(:capture_message).at_least(:once)
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
        VCR.use_cassette 'training/load_from_wiki' do
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
        VCR.use_cassette 'training/load_from_wiki' do
          slides = subject.load_content
          spanish = slides.first.translations.es
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
        VCR.use_cassette 'training/load_from_wiki' do
          modules = subject.load_content
          expect(modules.first.slug).not_to be_empty
        end
      end
    end

    describe 'for libraries' do
      let(:content_class) { TrainingLibrary }
      before do
        allow(content_class).to receive(:wiki_base_page)
          .and_return('Training modules/dashboard/libraries-test')
      end

      it 'returns an array of training content' do
        VCR.use_cassette 'training/load_from_wiki' do
          libraries = subject.load_content
          expect(libraries.first.slug).not_to be_empty
        end
      end
    end
  end
end
