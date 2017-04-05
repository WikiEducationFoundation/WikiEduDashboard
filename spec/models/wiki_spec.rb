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
    context "For valid wiki projects" do
      it 'allows valid language/project combinations' do
        created_wiki = build(:wiki, language: 'zh', project: 'wiktionary')
        expect(created_wiki).to be_valid
      end

      it 'allows nil language for wikidata' do
        create(:wiki, language: nil, project: 'wikidata')
        expect(Wiki.last.project).to eq('wikidata')
        expect(Wiki.last.language).to be_nil
      end

      it 'ensures nil language for wikidata' do
        create(:wiki, language: 'en', project: 'wikidata')
        expect(Wiki.last.project).to eq('wikidata')
        expect(Wiki.last.language).to be_nil
      end

      it 'allows nil language for wikisource' do
        wiki = create(:wiki, language: nil, project: 'wikisource')
        expect(wiki).to be_valid
      end

      it 'ensures the project and language combination are unique' do
        create(:wiki, language: 'zh', project: 'wiktionary')
        expect { create(:wiki, language: 'zh', project: 'wiktionary') }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "For invalid wiki projects" do
      let(:bad_language) { create(:wiki, language: 'xx', project: 'wikipedia') }
      it 'does not allow bad language codes' do
        expect { bad_language }.to raise_error(ActiveRecord::RecordInvalid)
      end

      let(:bad_project) { create(:wiki, language: 'en', project: 'wikinothing') }
      it 'does not allow bad projects' do
        expect { bad_project }.to raise_error(ActiveRecord::RecordInvalid)
      end

      let(:nil_language) { create(:wiki, language: nil, project: 'wikipedia') }
      it 'does not allow nil language for standard projects' do
        expect { nil_language }.to raise_error(Wiki::InvalidWikiError)
      end

      it 'does not allow duplicate wikidata projects because they all get set to language nil' do
        create(:wiki, language: nil, project: 'wikidata')
        expect { create(:wiki, language: 'zh', project: 'wikidata') }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it "it does not allow duplicate wikisource projects" do
        create(:wiki, language: nil, project: 'wikisource')
        expect { create(:wiki, language: nil, project: 'wikisource') }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it "it does not allow duplicate wikimedia incubator projects" do
        create(:wiki, language: 'incubator', project: 'wikimedia')
        expect { create(:wiki, language: 'incubator', project: 'wikimedia') }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '.get_or_create' do
    context 'when the record exists' do
      it 'returns the existing record' do
        new_wiki   = create(:wiki, language: 'zh', project: 'wiktionary')
        found_wiki = Wiki.get_or_create(language: 'zh', project: 'wiktionary')
        expect(new_wiki).to eq(found_wiki), -> { 'the pre existing wiki object was not found' }
      end

      context 'when the wiki project does not have language support' do
        it 'will ignore language but still return a record for wikidata' do
          new_wiki   = create(:wiki, language: nil, project: 'wikidata')
          found_wiki = Wiki.get_or_create(language: 'es', project: 'wikidata')
          expect(new_wiki).to eq(found_wiki), -> { "we did not find wikidata for language: 'es'" }
        end
      end

      context "for projects with a multilingual version in addition to language support" do
        context "when given a languge" do
          it "will return the approriate record" do
            new_wiki   = create(:wiki, language: "es", project: 'wikisource')
            found_wiki = Wiki.get_or_create(language: "es", project: 'wikisource')
            expect(new_wiki).to eq(found_wiki), -> { "Unfortunately the correct Wiki object was not returned" }
            expect(new_wiki.language).to eq('es')
          end
        end

        context "when not given a language" do
          it "will return a valid record" do
            new_wiki = create(:wiki, language: nil, project: 'wikisource')
            found_wiki = Wiki.get_or_create(language: nil, project: 'wikisource')
            expect(new_wiki).to eq(found_wiki), -> { "Unfortunately the correct Wiki object was not returned" }
          end
        end
      end
    end

    context 'when the record does not exist' do
      let(:project) { 'wiktionary' }
      let(:language) { 'zh' }

      it 'creates and returns the record' do
        expect(Wiki.find_by(language: language, project: project)).to be_nil
        wiki = Wiki.get_or_create(language: language, project: project)
        expect(wiki).to be_persisted
        expect(wiki.language).to eq(language)
        expect(wiki.project).to eq(project)
      end

      context 'when given nil language values on a multilingual project' do
        let(:project) { 'wikidata' }
        let(:language) { nil }

        it 'creates and returns the multilingual project' do
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

  describe '#base_url' do
    it 'returns the correct url for standard projects' do
      wiki = Wiki.get_or_create(language: 'es', project: 'wikibooks')
      expect(wiki.base_url).to eq('https://es.wikibooks.org')
    end

    it 'returns the correct url for wikidata' do
      wiki = Wiki.get_or_create(language: nil, project: 'wikidata')
      expect(wiki.base_url).to eq('https://www.wikidata.org')
    end

    it 'returns the correct url for wikimedia incubator' do
      wiki = Wiki.get_or_create(language: 'incubator', project: 'wikimedia')
      expect(wiki.base_url).to eq('https://incubator.wikimedia.org')
    end
  end
end
