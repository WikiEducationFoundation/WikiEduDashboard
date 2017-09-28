# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/rating_importer"

describe RatingImporter do
  describe '.update_ratings' do
    it 'should handle MediaWiki API errors' do
      error = MediawikiApi::ApiError.new
      stub_request(:any, %r{.*wikipedia\.org/w/api\.php.*query.*})
        .to_raise(error)

      create(:article,
             id: 1,
             title: 'Selfie',
             namespace: 0,
             rating: 'fa')

      article = Article.all.find_in_batches(batch_size: 30)
      RatingImporter.update_ratings(article)
      expect(Article.first.rating).to eq('fa')
    end
  end

  describe '.update_all_ratings and .update_new_ratings' do
    it 'should get latest ratings for articles' do
      VCR.use_cassette 'article/update_ratings' do
        course = create(:course,
                        id: 1,
                        title: 'Basket Weaving',
                        start: '2015-01-01'.to_date,
                        end: '2030-05-01'.to_date)
        # Add an article.
        article1 = create(:article,
                          id: 1,
                          title: 'Selfie',
                          namespace: 0)
        course.articles << article1

        possible_ratings = %w[fl fa a ga b c start stub list]

        # .update_ratings has a different flow for one rating vs. several,
        # so first we run an update with just one article.
        RatingImporter.update_new_ratings

        expect(possible_ratings).to include Article.find(1).rating

        article2 = create(:article,
                          id: 2,
                          title: 'A Clash of Kings',
                          namespace: 0)
        course.articles << article2
        RatingImporter.update_all_ratings
        expect(possible_ratings).to include Article.find(2).rating
      end
    end
  end
end
