# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_utils"

describe ArticleUtils do
  describe '.format_article_title' do
    it 'should capitalize the first letter and replace spaces with underscores' do
      title = 'boston trinity academy'
      formatted_title = described_class.format_article_title title
      expect(formatted_title).to eq('Boston_trinity_academy')
    end

    it 'should not mess with letters other than the first' do
      title = 'Boston Trinity Academy'
      formatted_title = described_class.format_article_title title
      expect(formatted_title).to eq('Boston_Trinity_Academy')
    end

    it 'should handle non-ASCII characters' do
      title = 'ábcde'
      formatted_title = described_class.format_article_title title
      expect(formatted_title).to eq('Ábcde')
      expect(title).to eq('ábcde')
    end
  end
end
