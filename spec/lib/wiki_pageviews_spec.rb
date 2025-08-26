# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_pageviews"

describe WikiPageviews do
  describe '.average_views_for_article' do
    let(:subject) { described_class.new(article).average_views }
    let(:article) { create(:article, title:) }

    context 'for a popular article' do
      let(:title) { 'Facebook' }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views' do
          expect(subject).to be > 500
        end
      end
    end

    context 'for an article with a slash in the title' do
      let(:title) { 'HIV/AIDS' }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views' do
          expect(subject).to be > 500
        end
      end
    end

    context 'for an article with an apostrophe in the title' do
      let(:title) { "Broussard's" }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views' do
          expect(subject).to be > 1
        end
      end
    end

    context 'for an article with quote marks in the title' do
      let(:title) { '"Weird_Al"_Yankovic' }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views' do
          expect(subject).to be > 50
        end
      end
    end

    context 'for an article with unicode characters in the title' do
      let(:title) { 'André_the_Giant' }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views' do
          expect(subject).to be > 50
        end
      end
    end

    context 'for a wikidata item' do
      let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
      let(:article) { create(:article, title: 'Q42', wiki: wikidata) }

      before { stub_wiki_validation }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views' do
          expect(subject).to be > 50
        end
      end
    end

    context 'for an article that does not exist' do
      let(:title) { 'THIS_IS_NOT_A_REAL_ARTICLE' }

      it 'returns 0' do
        VCR.use_cassette 'wiki_pageviews/average_views' do
          expect(subject).to eq(0)
        end
      end
    end

    context 'for an article that exist but has no view data' do
      let(:article) { create(:article, title:, wiki:) }
      let(:wiki) { create(:wiki, project: 'wikisource', language: 'fr') }
      let(:title) { 'Voyages,_aventures_et_combats/Chapitre_18' }
      let(:subject) { described_class.new(article).average_views }

      before { travel_to Date.new(2023, 10, 18) }

      after do
        travel_back
      end

      it 'returns 0' do
        VCR.use_cassette 'wiki_pageviews/404_handling' do
          expect(subject).to eq(0)
        end
      end
    end
  end
end
