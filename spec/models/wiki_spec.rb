# frozen_string_literal: true

# == Schema Information
#
# Table name: wikis
#
#  id       :integer          not null, primary key
#  language :string(16)
#  project  :string(16)
#

require 'rails_helper'

describe Wiki do
  describe 'validation' do
    context 'For valid wiki projects' do
      it 'allows valid language/project combinations' do
        VCR.use_cassette 'wiki' do
          created_wiki = build(:wiki, language: 'zh', project: 'wiktionary')
          expect(created_wiki).to be_valid
        end
      end

      it 'allows nil language for wikidata' do
        VCR.use_cassette 'wiki' do
          create(:wiki, language: nil, project: 'wikidata')
        end
        expect(Wiki.last.project).to eq('wikidata')
        expect(Wiki.last.language).to be_nil
      end

      it 'ensures nil language for wikidata' do
        VCR.use_cassette 'wiki' do
          create(:wiki, language: 'en', project: 'wikidata')
        end
        expect(Wiki.last.project).to eq('wikidata')
        expect(Wiki.last.language).to be_nil
      end

      it 'allows nil language for wikisource' do
        VCR.use_cassette 'wiki' do
          wiki = create(:wiki, language: nil, project: 'wikisource')
          expect(wiki).to be_valid
        end
      end

      it 'ensures the project and language combination are unique' do
        VCR.use_cassette('wiki') do
          create(:wiki, language: 'zh', project: 'wiktionary')
          expect { create(:wiki, language: 'zh', project: 'wiktionary') }
            .to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'For invalid wiki projects' do
      let(:bad_language) { create(:wiki, language: 'xx', project: 'wikipedia') }
      it 'does not allow bad language codes' do
        VCR.use_cassette('wiki') do
          expect { bad_language }.to raise_error(Wiki::InvalidWikiError)
        end
      end

      let(:bad_project) { create(:wiki, language: 'en', project: 'wikinothing') }
      it 'does not allow bad projects' do
        VCR.use_cassette('wiki') do
          expect { bad_project }.to raise_error(Wiki::InvalidWikiError)
        end
      end

      let(:nil_language) { create(:wiki, language: nil, project: 'wikipedia') }
      it 'does not allow nil language for standard projects' do
        expect { nil_language }.to raise_error(Wiki::InvalidWikiError)
      end

      it 'does not allow duplicate wikidata projects because they all get set to language nil' do
        VCR.use_cassette 'wiki' do
          create(:wiki, language: nil, project: 'wikidata')
        end
        expect { create(:wiki, language: 'zh', project: 'wikidata') }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'does not allow duplicate wikisource projects' do
        VCR.use_cassette 'wiki' do
          create(:wiki, language: nil, project: 'wikisource')
        end
        expect { create(:wiki, language: nil, project: 'wikisource') }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'does no allow wikisource with invalid language' do
        expect { create(:wiki, language: 'abcd', project: 'wikisource') }
          .to raise_error(Wiki::InvalidWikiError)
      end

      it 'does not allow non-existant wikis' do
        VCR.use_cassette('wiki') do
          expect { create(:wiki, language: 'dk', project: 'wikipedia') }
            .to raise_error(Wiki::InvalidWikiError)
        end
      end
    end
  end

  describe '.get_or_create' do
    context 'when the record exists' do
      it 'returns the existing record' do
        VCR.use_cassette('wiki') do
          new_wiki   = create(:wiki, language: 'zh', project: 'wiktionary')
          found_wiki = Wiki.get_or_create(language: 'zh', project: 'wiktionary')
          expect(new_wiki).to eq(found_wiki), -> { 'the pre existing wiki object was not found' }
        end
      end

      context 'when the wiki project does not have language support' do
        it 'will ignore language but still return a record for wikidata' do
          VCR.use_cassette 'wiki' do
            new_wiki = create(:wiki, language: nil, project: 'wikidata')
            found_wiki = Wiki.get_or_create(language: 'es', project: 'wikidata')
            expect(new_wiki).to eq(found_wiki), -> { "we did not find wikidata for language: 'es'" }
          end
        end
      end

      context 'for projects with a multilingual version in addition to language support' do
        context 'when given a languge' do
          it 'will return the approriate record' do
            VCR.use_cassette 'wiki' do
              new_wiki = create(:wiki, language: 'es', project: 'wikisource')
              found_wiki = Wiki.get_or_create(language: 'es', project: 'wikisource')
              expect(new_wiki).to eq(found_wiki),
                                  -> { 'Unfortunately the correct Wiki object was not returned' }
              expect(new_wiki.language).to eq('es')
            end
          end
        end

        context 'when not given a language' do
          it 'will return a valid record' do
            VCR.use_cassette 'wiki' do
              new_wiki = create(:wiki, language: nil, project: 'wikisource')
              found_wiki = Wiki.get_or_create(language: nil, project: 'wikisource')
              expect(new_wiki).to eq(found_wiki),
                                  -> { 'Unfortunately the correct Wiki object was not returned' }
            end
          end
        end
      end
    end

    context 'when the record does not exist' do
      let(:project) { 'wiktionary' }
      let(:language) { 'zh' }

      it 'creates and returns the record' do
        VCR.use_cassette('wiki') do
          expect(Wiki.find_by(language: language, project: project)).to be_nil
          wiki = Wiki.get_or_create(language: language, project: project)
          expect(wiki).to be_persisted
          expect(wiki.language).to eq(language)
          expect(wiki.project).to eq(project)
        end
      end

      context 'when given nil language values on a multilingual project' do
        let(:project) { 'wikidata' }
        let(:language) { nil }

        it 'creates and returns the multilingual project' do
          VCR.use_cassette 'wiki' do
            existing_record = Wiki.find_by(project: project)
            expect(existing_record).to be_nil

            wiki = Wiki.get_or_create(language: language, project: project)
            expect(wiki.project).to eq(project)
            expect(wiki.language).to eq(language)
            expect(wiki).to be_persisted
          end
        end
      end
    end
  end

  describe '#base_url' do
    it 'returns the correct url for standard projects' do
      VCR.use_cassette('wiki') do
        wiki = Wiki.get_or_create(language: 'es', project: 'wikibooks')
        expect(wiki.base_url).to eq('https://es.wikibooks.org')
      end
    end

    it 'returns the correct url for wikidata' do
      VCR.use_cassette 'wiki' do
        wiki = Wiki.get_or_create(language: nil, project: 'wikidata')
        expect(wiki.base_url).to eq('https://www.wikidata.org')
      end
    end

    it 'returns the correct url for wikimedia incubator' do
      VCR.use_cassette 'wiki' do
        wiki = Wiki.get_or_create(language: 'incubator', project: 'wikimedia')
        expect(wiki.base_url).to eq('https://incubator.wikimedia.org')
      end
    end
  end
end
