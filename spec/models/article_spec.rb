# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  views_updated_at         :date
#  namespace                :integer
#  rating                   :string(255)
#  rating_updated_at        :datetime
#  deleted                  :boolean          default(FALSE)
#  language                 :string(10)
#  average_views            :float(24)
#  average_views_updated_at :date
#  wiki_id                  :integer
#  mw_page_id               :integer
#  index_hash               :string(255)
#

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
    it 'gets the url for an article' do
      expect(@article.url).to eq('https://en.wikipedia.org/wiki/Selfie')
      expect(@sandbox.url).to eq('https://en.wikipedia.org/wiki/User:Ragesoss/sandbox')
      expect(@draft.url).to eq('https://en.wikipedia.org/wiki/Draft:My_Awesome_Draft!!!')
    end
  end

  describe '#full_title' do
    it 'gets the title including namespace prefix for an article' do
      expect(@article.full_title).to eq('Selfie')
      expect(@sandbox.full_title).to eq('User:Ragesoss/sandbox')
      expect(@draft.full_title).to eq('Draft:My Awesome Draft!!!')
    end
  end

  describe '#namespace_prefix' do
    let(:wiki) { create(:wiki, language: 'incubator', project: 'wikimedia') }
    let(:article) { create(:article, wiki:, namespace: Article::Namespaces::PROJECT) }

    it 'handles *.wikimedia.org wikis' do
      stub_wiki_validation
      expect(article.namespace_prefix).to eq('Incubator:')
    end
  end

  describe '#fetch_page_content' do
    let(:wiki) { build(:wiki, language: 'en', project: 'wikipedia') }
    let(:article) { create(:article, title: 'Selfies', namespace: 0, wiki:) }
    let(:wiki_api) { instance_double(WikiApi) }

    before do
      allow(WikiApi).to receive(:new).with(wiki).and_return(wiki_api)
    end

    it 'returns the page content when the API call is successful' do
      allow(wiki_api).to receive(:get_page_content).with(article.escaped_full_title).and_return(
        'Page content'
      )
      expect(article.fetch_page_content).to eq('Page content')
    end

    it 'returns an empty string when the API call returns 404' do
      allow(wiki_api).to receive(:get_page_content).with(article.escaped_full_title).and_return('')
      expect(article.fetch_page_content).to eq('')
    end

    it 'raises an error if the API call fails' do
      allow(wiki_api).to receive(:get_page_content).with(article.escaped_full_title).and_raise(
        StandardError, 'API Error'
      )
      expect { article.fetch_page_content }.to raise_error(StandardError, 'API Error')
    end

    it 'handles mediawiki 503 errors gracefully' do
      allow(wiki_api).to receive(:get_page_content).and_raise(
        WikiApi::PageFetchError.new(
          'Failed to fetch content for Ragesoss with response status: 503', 503
        )
      )

      expect { article.fetch_page_content }.to raise_error(
        WikiApi::PageFetchError,
        /Failed to fetch content for Ragesoss with response status: 503/
      )
    end
  end
end
