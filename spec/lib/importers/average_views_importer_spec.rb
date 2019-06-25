# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/average_views_importer"

describe AverageViewsImporter do
  let(:article) { create(:article, title: 'Selfie') }

  it 'saves average page views on Article records' do
    VCR.use_cassette 'average_views' do
      described_class.update_average_views([article])
    end
    expect(article.average_views).to be > 50
  end
end
