# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/average_views_importer"

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
    let!(:article_never_updated) do
      create(:article, title: 'Petrichor', average_views: 1, average_views_updated_at: nil)
    end

    let!(:article_very_old) do
      create(:article, title: 'ObsoleteTech', average_views: 1, average_views_updated_at: 2.months.ago) # rubocop:disable Layout/LineLength
    end

    it 'does not update recently-updated records' do
      course = create(:course)
      articles = [article, article_never_updated, article_very_old]
      articles.each { |a| create(:articles_course, article: a, course:) }
      described_class.update_outdated_average_views(course)
      expect(article.reload.average_views).to eq(1)
      expect(article_never_updated.reload.average_views).to eq(1)
      expect(article_very_old.reload.average_views).to eq(1)
    end
  end
end
