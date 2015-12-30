require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/importers/rating_importer"

describe ArticleImporter do
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

        possible_ratings = %w(fl fa a ga b c start stub list)

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

  describe '.update_article_status' do
    it 'should marked deleted articles as "deleted"' do
      course = create(:course,
                      end: '2016-12-31'.to_date)
      course.users << create(:user)
      create(:article,
             id: 1,
             title: 'Noarticle',
             namespace: 0)

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

    it 'should delete articles when id changed but new one already exists' do
      create(:article,
             id: 100,
             title: 'Audi',
             namespace: 0)
      create(:article,
             id: 848,
             title: 'Audi',
             namespace: 0)
      ArticleImporter.update_article_status
      expect(Article.find(100).deleted).to eq(true)
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
        deleted: false)
      expect(undeleted.count).to eq(1)
      expect(undeleted.first.id).to eq(second.id)
    end

    it 'should handle cases of space vs. underscore' do
      # This page was first moved from a sandbox to "Yōji Sakate", then
      # moved again to "Yōji Sakate (playwright)". It ended up in our database
      # like this.
      create(:article,
             id: 46745170,
             # Currently this is a redirect to the other title.
             title: 'Yōji Sakate',
             namespace: 0)
      create(:article,
             id: 46364485,
             # Current title is "Yōji Sakate (playwright)".
             title: 'Yōji_Sakate',
             namespace: 0)
      ArticleImporter.update_article_status
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

    it 'does not delete articles by mistake if Replica is down' do
      create(:article,
             id: 848,
             title: 'Audi',
             namespace: 0)
      create(:article,
             id: 1,
             title: 'Noarticle',
             namespace: 0)
      allow(Replica).to receive(:get_existing_articles_by_id).and_return(nil)
      ArticleImporter.update_article_status
      expect(Article.find(848).deleted).to eq(false)
      expect(Article.find(1).deleted).to eq(false)
    end
  end

  describe '.import_articles' do
    it 'should create an Article from a Wikipedia page_id' do
      ArticleImporter.import_articles [46349871]
      article = Article.find(46349871)
      expect(article.title).to eq('Kostanay')
    end
  end

  describe '.import_articles_by_title' do
    it 'should create an Article from a title' do
      titles = ['Selfie', 'Bombus_hortorum']
      VCR.use_cassette 'article_importer/existing_titles' do
        ArticleImporter.import_articles_by_title(titles)
      end
      expect(Article.find_by(title: 'Selfie')).to be_a(Article)
    end
    it 'should not create an article if there is no matching title' do
      titles = ['There_is_no_article_with_this_title']
      VCR.use_cassette 'article_importer/nonexistent_title' do
        ArticleImporter.import_articles_by_title(titles)
      end
      expect(Article.find_by(title: titles[0])).to be_nil
    end
  end
end
