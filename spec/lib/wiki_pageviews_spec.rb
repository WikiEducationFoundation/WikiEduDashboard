# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_pageviews"

describe WikiPageviews do
  describe '.views_for_article' do
    context 'for a popular article' do
      let(:article) { create(:article, title: 'Selfie') }
      let(:start_date) { '2015-10-01'.to_date }
      let(:end_date) { '2015-11-01'.to_date }
      let(:subject) do
        WikiPageviews.new(article).views_for_article(start_date: start_date,
                                                     end_date: end_date)
      end

      it 'returns a hash of daily views for all the requested dates' do
        VCR.use_cassette 'wiki_pageviews/views_for_article' do
          expect(subject).to be_a Hash
          expect(subject.count).to eq(32)
        end
      end

      it 'always returns the same value for a certain date' do
        VCR.use_cassette 'wiki_pageviews/views_for_article' do
          expect(subject['20151001']).to eq(2164)
        end
      end

      it 'fails gracefully with expected network errors' do
        stub_request(:any, /.*wikimedia.org.*/)
          .to_raise(Errno::ETIMEDOUT)
        expect(subject).to be_nil
      end

      it 're-raises unexpected errors' do
        stub_request(:any, /.*wikimedia.org.*/)
          .to_raise(StandardError)
        expect { subject }.to raise_error(StandardError)
      end

      it 'raises errors for unexpected API responses' do
        stub_request(:any, /.*wikimedia.org.*/)
          .to_return(status: 200, body: '{"type":"some error"}', headers: {})
        expect { subject }.to raise_error(WikiPageviews::PageviewApiError)
      end

      context 'beyond the allowed date range' do
        let(:start_date) { '2015-01-01'.to_date }
        it 'does not raise an error' do
          stub_request(:any, /.*wikimedia.org.*/)
            .to_return(
              status: 404,
              body: '{"type":"https://mediawiki.org/wiki/HyperSwitch/errors/not_found"}'
            )
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'for an unviewed article' do
      let(:article) { create(:article, title: title, wiki: wiki) }
      let(:wiki) { create(:wiki, project: 'wikisource', language: 'fr') }
      let(:title) { 'Voyages,_aventures_et_combats/Chapitre_18' }
      let(:start_date) { Date.new(2017, 4, 1) }
      let(:subject) do
        WikiPageviews.new(article).views_for_article(start_date: start_date,
                                                     end_date: start_date + 1.month)
      end

      it 'returns an empty hash' do
        VCR.use_cassette 'wiki_pageviews/views_for_unviewed_article' do
          expect(subject).to be_a Hash
          expect(subject.count).to eq(0)
        end
      end
    end
  end

  describe '.average_views_for_article' do
    let(:subject) { WikiPageviews.new(article).average_views }
    let(:article) { create(:article, title: title) }

    context 'for a popular article' do
      let(:title) { 'Selfie' }
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

    context 'for an article that does not exist' do
      let(:title) { 'THIS_IS_NOT_A_REAL_ARTICLE' }
      it 'returns 0' do
        VCR.use_cassette 'wiki_pageviews/average_views' do
          expect(subject).to eq(0)
        end
      end
    end

    context 'for an article that exist but has no view data' do
      let(:article) { create(:article, title: title, wiki: wiki) }
      let(:wiki) { create(:wiki, project: 'wikisource', language: 'fr') }
      let(:title) { 'Voyages,_aventures_et_combats/Chapitre_18' }
      let(:subject) { WikiPageviews.new(article).average_views }
      it 'returns 0' do
        VCR.use_cassette 'wiki_pageviews/404_handling' do
          expect(subject).to eq(0)
        end
      end
    end
  end
end
