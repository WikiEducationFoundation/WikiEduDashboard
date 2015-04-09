require 'rails_helper'

describe Grok do
  describe 'API requests' do
    it 'should get page view data for a given article' do
      VCR.use_cassette 'grok/pageview_data' do
        title = 'History of Biology'
        response = Grok.views_for_article(title, '2014-08-01'.to_date, 'en')
        expect(response).to be
      end
    end

    it 'should handle timeout errors' do
      stub_request(:any, %r{.*}).to_raise(Errno::ETIMEDOUT)
      response = Grok.views_for_article('Foo', '2014-08-01'.to_date, 'en')
    end
  end

  describe 'API response parsing' do
    it 'should return page views for a given article in a certain date range' do
      VCR.use_cassette 'grok/pageview_data' do
        title = 'History of biology'
        views = Grok.views_for_article(title, '2014-09-18'.to_date, 'en')

        # Check for the expected total views over a date range.
        view_sum = 0
        views.each do |day, count|
          view_sum += count if day.to_date <= '2014-12-23'.to_date
        end
        expect(view_sum).to eq(22_961)

        # Check for the expected views on a single day.
        expect(views['2014-09-30']).to eq(267)
      end
    end
  end
end
