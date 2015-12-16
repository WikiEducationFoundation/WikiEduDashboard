require 'rails_helper'
require "#{Rails.root}/lib/wiki_pageviews"

describe WikiPageviews do
  describe '.views_for_article' do
    context 'for a popular article' do
      let(:title) { 'Selfie' }
      let(:start_date) { '2015-10-01'.to_date }
      let(:end_date) { '2015-11-01'.to_date }
      let(:subject) do
        WikiPageviews.views_for_article(title, start_date: start_date,
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

      context 'beyond the allowed date range' do
        let(:start_date) { '2015-01-01'.to_date }
        it 'raises an error' do
          expect{ subject }.to raise_error('invalid WikiPageviews start date')
        end
      end
    end
  end

  describe '.average_views_for_article' do
    let(:subject) { WikiPageviews.average_views_for_article(title) }

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
      it 'returns nil' do
        VCR.use_cassette 'wiki_pageviews/average_views' do
          expect(subject).to be_nil
        end
      end
    end
  end
end
