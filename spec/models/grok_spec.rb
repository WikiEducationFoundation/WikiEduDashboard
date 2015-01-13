require 'rails_helper'

describe Grok do

  describe "API requests" do
    it "should get page view data for a given article" do
      VCR.use_cassette "grok/pageview_data" do
        response = Grok.get_month_views_for_article "History of Biology"
        expect(response).to be
      end
    end
  end

  describe "API response parsing" do
    it "should return monthly page views for a given article" do
      VCR.use_cassette "grok/pageview_data" do
        total = Grok.get_month_views_for_article "History of biology", "201409"
        expect(total).to equal(8918)
      end
    end

    it "should return page views for a given article after a certain date" do
      VCR.use_cassette "grok/pageview_data" do
        views = Grok.get_views_since_date_for_article "History of biology", "2014-09-18".to_date
        expect(views.count).to equal(105)
      end
    end

    it "should return daily page views for a given article" do
      VCR.use_cassette "grok/pageview_data" do
        total = Grok.get_day_views_for_article "History of biology", "2014-09-18".to_date
        expect(total).to equal(275)
      end
    end
  end

  describe "Public methods" do
  end

end