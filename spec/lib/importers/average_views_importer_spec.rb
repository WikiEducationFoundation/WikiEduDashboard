# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/importers/average_views_importer')

describe AverageViewsImporter do
  let!(:article) do
    create(:article, title: 'Selfie', average_views: 1, average_views_updated_at: 1.day.ago)
  end

  describe '.update_average_views' do
    it 'saves average page views on Article records' do
      VCR.use_cassette 'average_views' do
        described_class.update_average_views(Article.all)
      end
      expect(article.reload.average_views).to be > 50
    end
  end

  describe '.update_outdated_average_views' do
    it 'does not update recently-updated records' do
      described_class.update_outdated_average_views(Article.all)
      expect(article.reload.average_views).to eq(1)
    end
  end
end
