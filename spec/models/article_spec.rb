# frozen_string_literal: true

require 'rails_helper'

describe Article, type: :model do
  before(:all) do
    # Create some articles in different namespaces
    @article = build(:article,
                     title: 'Selfie',
                     namespace: 0,
                     views_updated_at: '2014-12-31'.to_date)
    @sandbox = build(:article, namespace: 2, title: 'Ragesoss/sandbox')
    @draft = build(:article, namespace: 118, title: 'My_Awesome_Draft!!!')
  end

  describe '#url' do
    it 'should get the url for an article' do
      expect(@article.url).to eq('https://en.wikipedia.org/wiki/Selfie')
      expect(@sandbox.url).to eq('https://en.wikipedia.org/wiki/User:Ragesoss/sandbox')
      expect(@draft.url).to eq('https://en.wikipedia.org/wiki/Draft:My_Awesome_Draft!!!')
    end
  end

  describe '#full_title' do
    it 'should get the title including namespace prefix for an article' do
      expect(@article.full_title).to eq('Selfie')
      expect(@sandbox.full_title).to eq('User:Ragesoss/sandbox')
      expect(@draft.full_title).to eq('Draft:My Awesome Draft!!!')
    end
  end
end
