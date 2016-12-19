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

describe Wiki, type: :model do
  describe 'validation' do
    let(:create_wiki) { create(:wiki, language: 'zh', project: 'wiktionary') }
    subject { create_wiki.valid? }
    it 'allows valid language/project combinations' do
      expect(subject).to eq(true)
    end

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

    let(:create_wikidata) { create(:wiki, language: nil, project: 'wikidata') }
    it 'allows nil language for wikidata' do
      create_wikidata
      expect(Wiki.last.project).to eq('wikidata')
      expect(Wiki.last.language).to be_nil
    end

    let(:create_en_wikidata) { create(:wiki, language: 'en', project: 'wikidata') }
    it 'ensures nil language for wikidata' do
      create_en_wikidata
      expect(Wiki.last.project).to eq('wikidata')
      expect(Wiki.last.language).to be_nil
    end

    it 'ensures the project and language combination are unique' do
      create(:wiki, language: 'zh', project: 'wiktionary')
      expect { create(:wiki, language: 'zh', project: 'wiktionary') }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'does not allow duplicate multilingual projects' do
      create(:wiki, language: nil, project: 'wikidata')
      expect { create(:wiki, language: 'zh', project: 'wikidata') }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '.get' do
    let(:subject) { Wiki.get(language: language, project: project) }
    let(:language) { 'zh' }
    let(:project) { 'wiktionary' }

    context 'when the record exists' do
      before do
        create(:wiki, language: language, project: project, id: 1001)
      end
      it 'returns the existing record' do
        expect(subject.id).to eq(1001)
      end

      before do
        create(:wiki, language: nil, project: 'wikidata', id: 1002)
      end
      it 'ignores language for wikidata and still returns the record' do
        subject = Wiki.get(language: 'es', project: 'wikidata')
        expect(subject.id).to eq(1002)
        expect(subject.language).to be_nil
      end
    end

    context 'when the record does not exist' do
      it 'creates and returns the record' do
        existing_record = Wiki.find_by(language: language, project: project)
        expect(existing_record).to be_nil
        expect(subject.language).to eq(language)
        expect(subject.project).to eq(project)
        expect(subject.id).not_to be_nil
      end

      it 'creates and returns a multilingual project' do
        existing_record = Wiki.find_by(project: 'wikidata')
        expect(existing_record).to be_nil
        subject = Wiki.get(language: nil, project: 'wikidata')
        expect(subject.project).to eq('wikidata')
        expect(subject.id).not_to be_nil
      end
    end
  end

  describe '#base_url' do
    it 'returns the correct url for standard projects' do
      subject = Wiki.get(language: 'es', project: 'wikibooks')
      expect(subject.base_url).to eq('https://es.wikibooks.org')
    end

    it 'returns the correct url for wikidata' do
      subject = Wiki.get(language: nil, project: 'wikidata')
      expect(subject.base_url).to eq('https://www.wikidata.org')
    end
  end
end
