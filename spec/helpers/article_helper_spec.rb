# frozen_string_literal: true

require 'rails_helper'

describe ArticleHelper, type: :helper do
  before(:all) do
    # Create some articles in different namespaces
    @article = build(:article,
                     title: 'Selfie',
                     namespace: 0,
                     views_updated_at: '2014-12-31'.to_date)
    @sandbox = build(:article, namespace: 2, title: 'Ragesoss/sandbox')
    @draft = build(:article, namespace: 118, title: 'My_Awesome_Draft!!!')
  end

  describe '.article_url' do
    it 'should get the url for an article' do
      # rubocop:disable Metrics/LineLength
      expect(article_url(@article)).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Selfie")
      expect(article_url(@sandbox)).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/User:Ragesoss/sandbox")
      expect(article_url(@draft)).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Draft:My_Awesome_Draft!!!")
      # rubocop:enable Metrics/LineLength
    end
  end

  describe '.full_title' do
    it 'should get the title including namespace prefix for an article' do
      expect(full_title(@article)).to eq('Selfie')
      expect(full_title(@sandbox)).to eq('User:Ragesoss/sandbox')
      expect(full_title(@draft)).to eq('Draft:My Awesome Draft!!!')
    end
  end

  describe '.rating_display' do
    it 'displays bplus as b class' do
      output = rating_display('bplus')
      expect(output).to eq('b')
    end

    it 'displays a/ga as a class' do
      output = rating_display('a/ga')
      expect(output).to eq('a')
    end

    it 'displays rated lists as basic lists' do
      output = rating_display('al')
      expect(output).to eq('l')
    end
  end
end
