# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_pageviews"

describe WikiPageviews do
  describe '.average_views_from_date' do
    let(:start_date) { Date.new(2025, 8, 15) }
    let(:article) { create(:article, title:) }
    let(:subject) { described_class.new(article).average_views_from_date(start_date) }

    before { travel_to Date.new(2025, 8, 20) }

    after { travel_back }

    context 'for a popular article' do
      let(:title) { 'Facebook' }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views_from_date' do
          expect(subject).to eq(21194.4)
        end
      end
    end

    context 'for an article with a slash in the title' do
      let(:title) { 'HIV/AIDS' }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views_from_date' do
          expect(subject).to eq(2177.6)
        end
      end
    end

    context 'for an article with an apostrophe in the title' do
      let(:title) { "Broussard's" }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views_from_date' do
          expect(subject).to eq(8.4)
        end
      end
    end

    context 'for an article with quote marks in the title' do
      let(:title) { '"Weird_Al"_Yankovic' }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views_from_date' do
          expect(subject).to eq(20947)
        end
      end
    end

    context 'for an article with unicode characters in the title' do
      let(:title) { 'André_the_Giant' }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views_from_date' do
          expect(subject).to eq(5951.4)
        end
      end
    end

    context 'for a wikidata item' do
      let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
      let(:article) { create(:article, title: 'Q42', wiki: wikidata) }

      before { stub_wiki_validation }

      it 'returns the average page views' do
        VCR.use_cassette 'wiki_pageviews/average_views_from_date' do
          expect(subject).to eq(101.8)
        end
      end
    end

    context 'for an article that does not exist' do
      let(:title) { 'THIS_IS_NOT_A_REAL_ARTICLE' }

      it 'returns 0' do
        VCR.use_cassette 'wiki_pageviews/average_views_from_date' do
          expect(subject).to eq(0)
        end
      end
    end

    context 'for an article that exist but has no view data' do
      let(:article) { create(:article, title:, wiki:) }
      let(:wiki) { create(:wiki, project: 'wikisource', language: 'fr') }
      let(:title) { 'Voyages,_aventures_et_combats/Chapitre_18' }
      let(:subject) { described_class.new(article).average_views_from_date(start_date) }

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

    context 'for an empty period of time' do
      let(:title) { 'Facebook' }
      let(:start_date) { Date.new(2025, 8, 23) }

      it 'returns 0' do
        expect(subject).to eq(0)
      end
    end

    context 'for a nil start date' do
      let(:title) { 'Facebook' }
      let(:start_date) { nil }

      it 'returns 0' do
        expect(subject).to eq(0)
      end
    end
  end
end
