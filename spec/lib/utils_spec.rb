require 'rails_helper'
require "#{Rails.root}/lib/utils"

describe Utils do
  describe '.parse_json' do
    it 'should handle unparseable json' do
      not_json = '<xml_is_great>Wat?</xml_is_great>'
      Utils.parse_json(not_json)
    end
  end

  describe '.format_article_title' do
    it 'should capitalize the first letter and replace spaces with underscores' do
      title = 'boston trinity academy'
      formatted_title = Utils.format_article_title title
      expect(formatted_title).to eq('Boston_trinity_academy')
    end

    it 'should not mess with letters other than the first' do
      title = 'Boston Trinity Academy'
      formatted_title = Utils.format_article_title title
      expect(formatted_title).to eq('Boston_Trinity_Academy')
    end

    it 'should handle non-ASCII characters' do
      title = 'ábcde'
      formatted_title = Utils.format_article_title title
      expect(formatted_title).to eq('Ábcde')
    end
  end
end
