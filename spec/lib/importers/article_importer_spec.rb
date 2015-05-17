require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"

describe ArticleImporter do
  describe '.update_ratings' do
    it 'should handle MediaWiki API errors' do
      error = MediawikiApi::ApiError.new nil
      allow(error).to receive(:data).and_return({})
      allow(error).to receive(:info).and_return('bar')
      stub_request(:any, %r{.*wikipedia\.org/w/api\.php.*query.*})
        .to_raise(error)

      create(:article,
             id: 1,
             title: 'Selfie',
             namespace: 0,
             rating: 'fa'
      )

      article = Article.all.find_in_batches(batch_size: 30)
      ArticleImporter.update_ratings(article)
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
                        end: '2015-05-01'.to_date
                      )
        # Add an article.
        article1 = create(:article,
               id: 1,
               title: 'Selfie',
               namespace: 0
        )
        course.articles << article1

        possible_ratings = %w(fl fa a ga b c start stub list)

        # .update_ratings has a different flow for one rating vs. several,
        # so first we run an update with just one article.
        ArticleImporter.update_new_ratings

        pp Article.all.first
        expect(possible_ratings).to include Article.all.first.rating

        article2 = create(:article,
               id: 2,
               title: 'A Clash of Kings',
               namespace: 0
        )
        course.articles << article2

        ArticleImporter.update_all_ratings
        expect(possible_ratings).to include Article.all.last.rating
      end
    end
  end

  describe '.update_article_status' do
    it 'should marked deleted articles as "deleted"' do
      course = create(:course,
                      end: '2016-12-31'.to_date
      )
      course.users << create(:user)
      create(:article,
             id: 1,
             title: 'Noarticle',
             namespace: 0
      )

      ArticleImporter.update_article_status
      expect(Article.find(1).deleted).to be true
    end

    it 'should update the ids of articles' do
      create(:article,
             id: 100,
             title: 'Audi',
             namespace: 0)

      ArticleImporter.update_article_status
      expect(Article.find_by(title: 'Audi').id).to eq(848)
    end

    it 'should update the namespace are moved articles' do
      create(:article,
             id: 848,
             title: 'Audi',
             namespace: 2)

      ArticleImporter.update_article_status
      expect(Article.find_by(title: 'Audi').namespace).to eq(0)
    end

    it 'should handle cases where there are two ids for one page' do
      first = create(:article,
             id: 2262715,
             title: 'Kostanay',
             namespace: 0)
      second = create(:article,
             id: 46349871,
             title: 'Kostanay',
             namespace: 0)
      ArticleImporter.resolve_duplicate_articles([first])
      undeleted = Article.where(
        title: 'Kostanay',
        namespace: 0,
        deleted: false
      )
      expect(undeleted.count).to eq(1)
      expect(undeleted.first.id).to eq(second.id)
    end

    it 'should handle case-variant titles' do
      article1 = create(:article,
                        id: 3914927,
                        title: 'Cyber-ethnography',
                        deleted: true,
                        namespace: 1)
      article2 = create(:article,
                        id: 46394760,
                        title: 'Cyber-Ethnography',
                        deleted: false,
                        namespace: 1)
      ArticleImporter.update_article_status
      expect(article1.id).to eq(3914927)
      expect(article2.id).to eq(46394760)
    end

    it 'should update the article_id for revisions when article_id changes' do
      create(:article,
             id: 2262715,
             title: 'Kostanay',
             namespace: 0)
      create(:revision,
             id: 648515801,
             article_id: 2262715)
      ArticleImporter.update_article_status

      new_article = Article.find_by(title: 'Kostanay')
      expect(new_article.id).to eq(46349871)
      expect(new_article.revisions.count).to eq(1)
    end
  end
end
