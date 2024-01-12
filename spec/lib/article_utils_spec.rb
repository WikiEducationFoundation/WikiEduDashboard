# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/article_utils')

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
end
