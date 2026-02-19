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

  describe '.default_class' do
    it 'returns standard ratings as-is' do
      %w[fa fl a ga b c start stub list].each do |rating|
        expect(default_class(rating)).to eq(rating)
      end
    end

    it 'maps a/ga composite rating to a' do
      expect(default_class('a/ga')).to eq('a')
    end

    it 'maps French ratings correctly' do
      expect(default_class('adq')).to eq('fa')
      expect(default_class('ba')).to eq('ga')
      expect(default_class('bd')).to eq('start')
      expect(default_class('e')).to eq('stub')
    end

    it 'maps Turkish ratings correctly' do
      expect(default_class('sm')).to eq('fa')
      expect(default_class('km')).to eq('ga')
      expect(default_class('taslak')).to eq('stub')
    end

    it 'maps Hungarian ratings correctly' do
      expect(default_class('teljes')).to eq('b')
    end

    it 'maps Arabic ratings correctly' do
      expect(default_class('م.مخ')).to eq('fa')
      expect(default_class('أ')).to eq('ga')
      expect(default_class('ب')).to eq('b')
      expect(default_class('ج')).to eq('c')
      expect(default_class('بداية')).to eq('start')
      expect(default_class('بذرة')).to eq('stub')
    end

    it 'maps Chinese ratings correctly' do
      expect(default_class('典范条目')).to eq('fa')
      expect(default_class('特色列表')).to eq('fl')
      expect(default_class('优良条目')).to eq('ga')
      expect(default_class('甲级条目')).to eq('a')
      expect(default_class('乙级条目')).to eq('b')
      expect(default_class('丙级条目')).to eq('c')
      expect(default_class('初级条目')).to eq('start')
      expect(default_class('小作品级条目')).to eq('stub')
      expect(default_class('列表级条目')).to eq('list')
    end

    it 'returns nil for unknown ratings' do
      expect(default_class('unknown')).to be_nil
      expect(default_class('xyz')).to be_nil
    end
  end
end
