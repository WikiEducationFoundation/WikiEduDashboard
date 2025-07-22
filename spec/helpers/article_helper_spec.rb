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
    it 'gets the url for an article' do
      expect(@article.url).to eq('https://en.wikipedia.org/wiki/Selfie')
      expect(@sandbox.url).to eq('https://en.wikipedia.org/wiki/User:Ragesoss/sandbox')
      expect(@draft.url).to eq('https://en.wikipedia.org/wiki/Draft:My_Awesome_Draft!!!')
    end
  end

  describe '.full_title' do
    it 'gets the title including namespace prefix for an article' do
      expect(@article.full_title).to eq('Selfie')
      expect(@sandbox.full_title).to eq('User:Ragesoss/sandbox')
      expect(@draft.full_title).to eq('Draft:My Awesome Draft!!!')
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
