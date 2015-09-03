require 'rails_helper'
require "#{Rails.root}/lib/importers/view_importer"

describe ViewImporter do
  describe '.update_views_for_article' do
    it 'should not fail if there are no revisions for an article' do
      article = create(:article,
                       title: 'Selfie',
                       views_updated_at: '2015-01-01')
      ViewImporter.update_views_for_article(article)
    end
  end

  describe '.update_all_views' do
    it 'should get view data for all articles' do
      VCR.use_cassette 'article/update_all_views' do
        # Try it with no articles.
        ViewImporter.update_all_views

        # Add an article
        build(:article,
              id: 1,
              title: 'Wikipedia',
              namespace: 0,
              views_updated_at: '2014-12-31'.to_date).save

        # Course, article-course, and revision are also needed.
        build(:course,
              id: 1,
              start: '2014-01-01'.to_date).save
        build(:articles_course,
              id: 1,
              course_id: 1,
              article_id: 1).save
        build(:revision,
              article_id: 1).save

        # Update again with this article.
        ViewImporter.update_all_views(true)
      end
    end
  end

  describe '.update_new_views' do
    it 'should get view data for new articles' do
      VCR.use_cassette 'article/update_new_views' do
        # Try it with no articles.
        ViewImporter.update_new_views

        # Add an article.
        build(:article,
              id: 1,
              title: 'Wikipedia',
              namespace: 0).save

        # Course, article-course, and revision are also needed.
        build(:course,
              id: 1,
              start: '2014-01-01'.to_date).save
        build(:articles_course,
              id: 1,
              course_id: 1,
              article_id: 1).save
        build(:revision,
              article_id: 1).save

        # Update again with this article.
        ViewImporter.update_new_views
        ViewImporter.update_all_views(true)
      end
    end
  end
end
