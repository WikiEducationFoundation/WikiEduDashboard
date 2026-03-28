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
        expect(described_class.last.project).to eq('wikidata')
        expect(described_class.last.language).to be_nil
      end

      it 'ensures nil language for wikidata' do
        VCR.use_cassette 'wiki' do
          create(:wiki, language: 'en', project: 'wikidata')
        end
        expect(described_class.last.project).to eq('wikidata')
        expect(described_class.last.language).to be_nil
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
      let(:bad_project) { create(:wiki, language: 'en', project: 'wikinothing') }
      let(:nil_language) { create(:wiki, language: nil, project: 'wikipedia') }

      it 'does not allow bad language codes' do
        VCR.use_cassette('wiki') do
          expect { bad_language }.to raise_error(Wiki::InvalidWikiError)
        end
      end

      it 'does not allow bad projects' do
        VCR.use_cassette('wiki') do
          expect { bad_project }.to raise_error(Wiki::InvalidWikiError)
        end
      end

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
          found_wiki = described_class.get_or_create(language: 'zh', project: 'wiktionary')
          expect(new_wiki).to eq(found_wiki), -> { 'the pre existing wiki object was not found' }
        end
      end

      context 'when the wiki project does not have language support' do
        it 'will ignore language but still return a record for wikidata' do
          VCR.use_cassette 'wiki' do
            new_wiki = create(:wiki, language: nil, project: 'wikidata')
            found_wiki = described_class.get_or_create(language: 'es', project: 'wikidata')
            expect(new_wiki).to eq(found_wiki), -> { "we did not find wikidata for language: 'es'" }
          end
        end
      end

      context 'for projects with a multilingual version in addition to language support' do
        context 'when given a languge' do
          it 'will return the approriate record' do
            VCR.use_cassette 'wiki' do
              new_wiki = create(:wiki, language: 'es', project: 'wikisource')
              found_wiki = described_class.get_or_create(language: 'es', project: 'wikisource')
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
              found_wiki = described_class.get_or_create(language: nil, project: 'wikisource')
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
          expect(described_class.find_by(language:, project:)).to be_nil
          wiki = described_class.get_or_create(language:, project:)
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
            existing_record = described_class.find_by(project:)
            expect(existing_record).to be_nil

            wiki = described_class.get_or_create(language:, project:)
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
        wiki = described_class.get_or_create(language: 'es', project: 'wikibooks')
        expect(wiki.base_url).to eq('https://es.wikibooks.org')
      end
    end

    it 'returns the correct url for wikidata' do
      VCR.use_cassette 'wiki' do
        wiki = described_class.get_or_create(language: nil, project: 'wikidata')
        expect(wiki.base_url).to eq('https://www.wikidata.org')
      end
    end

    it 'returns the correct url for wikimedia incubator' do
      VCR.use_cassette 'wiki' do
        wiki = described_class.get_or_create(language: 'incubator', project: 'wikimedia')
        expect(wiki.base_url).to eq('https://incubator.wikimedia.org')
      end
    end
  end

  describe '#edit_templates' do
    before do
      @dashboard_url = ENV['dashboard_url']
      ENV['dashboard_url'] = 'outreachdashboard.wmflabs.org'
    end

    after do
      ENV['dashboard_url'] = @dashboard_url
    end

    it 'works with non-Wikipedia wikis' do
      VCR.use_cassette 'wiki' do
        wiki = described_class.get_or_create(language: 'pt', project: 'wikiversity')
        templates = wiki.edit_templates
        expect(templates['default']['course']).to eq('Detalhes de programa')
      end
    end
  end

  describe '.parse_interwiki_format' do
    it 'returns nil for non-interwiki titles' do
      expect(described_class.parse_interwiki_format('Simple Article')).to be_nil
    end

    it 'parses a simple language prefix' do
      expect(described_class.parse_interwiki_format('en:Article'))
        .to eq(['Article', 'wikipedia', 'en'])
    end

    it 'parses a project and language prefix' do
      expect(described_class.parse_interwiki_format('wikt:fr:Word'))
        .to eq(['Word', 'wiktionary', 'fr'])
    end

    it 'parses a project prefix for multilingual projects' do
      expect(described_class.parse_interwiki_format('wikidata:Q1'))
        .to eq(['Q1', 'wikidata', nil])
    end

    it 'correctly handles titles with additional colons' do
      expect(described_class.parse_interwiki_format('en:Category:Physics'))
        .to eq(['Category:Physics', 'wikipedia', 'en'])
    end

    it 'correctly handles Meta-Wiki shorthand' do
      expect(described_class.parse_interwiki_format('m:Main_Page'))
        .to eq(['Main_Page', 'wikimedia', 'meta'])
    end

    it 'correctly handles Commons shorthand' do
      expect(described_class.parse_interwiki_format('c:File:Example.jpg'))
        .to eq(['File:Example.jpg', 'wikimedia', 'commons'])
    end

    it 'rejects internal site namespaces that look like projects but are not' do
      expect(described_class.parse_interwiki_format('Wikipedia:Help')).to be_nil
      expect(described_class.parse_interwiki_format('Special:Random')).to be_nil
    end

    it 'handles a leading colon correctly' do
      expect(described_class.parse_interwiki_format(':en:Article'))
        .to eq(['Article', 'wikipedia', 'en'])
    end

    it 'returns nil for empty or nil input' do
      expect(described_class.parse_interwiki_format('')).to be_nil
      expect(described_class.parse_interwiki_format(nil)).to be_nil
    end
  end
end
