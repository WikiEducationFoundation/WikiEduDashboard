# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_utils"

class MockWiktionary
  def self.project
    'wiktionary'
  end
end

describe ArticleUtils do
  describe '.format_article_title' do
    it 'capitalizes the first letter and replace spaces with underscores' do
      title = 'boston trinity academy'
      formatted_title = described_class.format_article_title title
      expect(formatted_title).to eq('Boston_trinity_academy')
    end

    it 'does not mess with letters other than the first' do
      title = 'Boston Trinity Academy'
      formatted_title = described_class.format_article_title title
      expect(formatted_title).to eq('Boston_Trinity_Academy')
    end

    it 'handles non-ASCII characters' do
      title = 'ábcde'
      formatted_title = described_class.format_article_title title
      expect(formatted_title).to eq('Ábcde')
      expect(title).to eq('ábcde')
    end

    it 'does not capitalize wiktionary titles' do
      title = 'derívense'
      formatted_title = described_class.format_article_title title, MockWiktionary
      expect(formatted_title).to eq('derívense')
    end
  end

  # Handle interwiki link format
  describe '.parse_interwiki_format' do
    it 'parses simple interwiki format (en:Article)' do
      result = described_class.parse_interwiki_format('en:Slavonic Library in Prague')
      expect(result).to eq({
        title: 'Slavonic Library in Prague',
        project: 'wikipedia',
        language: 'en'
      })
    end

    it 'parses interwiki format with project (es:wiktionary:palabra)' do
      result = described_class.parse_interwiki_format('es:wiktionary:palabra')
      expect(result).to eq({
        title: 'palabra',
        project: 'wiktionary',
        language: 'es'
      })
    end

    it 'parses interwiki format with project abbreviation (en:wikt:hello)' do
      result = described_class.parse_interwiki_format('en:wikt:hello')
      expect(result).to eq({
        title: 'hello',
        project: 'wiktionary',
        language: 'en'
      })
    end

    it 'parses interwiki format with other projects (de:b:Mathematik)' do
      result = described_class.parse_interwiki_format('de:b:Mathematik')
      expect(result).to eq({
        title: 'Mathematik',
        project: 'wikibooks',
        language: 'de'
      })
    end

    it 'handles titles with colons (en:User:Example)' do
      result = described_class.parse_interwiki_format('en:User:Example')
      expect(result).to eq({
        title: 'User:Example',
        project: 'wikipedia',
        language: 'en'
      })
    end

    it 'returns nil for non-interwiki format (Engineer:Something)' do
      result = described_class.parse_interwiki_format('Engineer:Something')
      expect(result).to be_nil
    end

    it 'returns nil for regular article titles (Boston Trinity Academy)' do
      result = described_class.parse_interwiki_format('Boston Trinity Academy')
      expect(result).to be_nil
    end

    it 'returns nil for category pages (Category:Photography)' do
      result = described_class.parse_interwiki_format('Category:Photography')
      expect(result).to be_nil
    end
  end
end
