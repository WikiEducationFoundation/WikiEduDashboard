# == Schema Information
#
# Table name: articles
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  views                    :integer          default(0)
#  created_at               :datetime
#  updated_at               :datetime
#  character_sum            :integer          default(0)
#  revision_count           :integer          default(0)
#  views_updated_at         :date
#  namespace                :integer
#  rating                   :string(255)
#  rating_updated_at        :datetime
#  deleted                  :boolean          default(FALSE)
#  language                 :string(10)
#  average_views            :float(24)
#  average_views_updated_at :date
#

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/importers/view_importer"

describe Article do
  describe '#update' do
    it 'should do a null update for an article' do
      VCR.use_cassette 'article/update' do
        # Add an article
        article = build(:article,
                        id: 1,
                        title: 'Selfie',
                        namespace: 0,
                        views_updated_at: '2014-12-31'.to_date)

        # Run update with no revisions
        article.update
        expect(article.views).to eq(0)

        # Add a revision and update again.
        build(:revision,
              article_id: 1,
              views: 10).save
        article.update
        expect(article.views).to eq(10)
      end
    end
  end

  describe '#update_views' do
    it 'should fetch new views for an article' do
      VCR.use_cassette 'article/update_views' do
        # Add an article
        article = build(:article,
                        id: 1,
                        title: 'Wikipedia',
                        namespace: 0,
                        views_updated_at: '2014-12-31'.to_date)

        # Add a revision so that update_views has something to run on.
        build(:revision,
              article_id: 1).save
        ViewImporter.update_views_for_article article
        expect(article.views).to be > 0
      end
    end
  end

  describe 'cache methods' do
    it 'should update article cache data' do
      # Add an article
      article = build(:article,
                      id: 1,
                      title: 'Selfie',
                      namespace: 0,
                      views_updated_at: '2014-12-31'.to_date)

      # Add a revision so that update_views has something to run on.
      build(:revision,
            article_id: 1).save

      article.update_cache
      expect(article.revision_count).to be_kind_of(Integer)
      expect(article.character_sum).to be_kind_of(Integer)
    end
  end

  describe '.update_all_caches' do
    it 'should update caches for articles' do
      # Try it with no articles.
      Article.update_all_caches

      # Add an article.
      build(:article,
            id: 1,
            title: 'Selfie',
            namespace: 0).save

      # Update again with this article.
      Article.update_all_caches
    end
  end

  describe 'deleted articles' do
    it 'should not contribute to cached course values' do
      course = create(:course, end: '2016-12-31'.to_date)
      course.users << create(:user, id: 1)
      CoursesUsers.update_all(role: CoursesUsers::Roles::STUDENT_ROLE)
      (1..2).each do |i|
        article = create(:article,
                         id: i,
                         title: "Basket Weaving #{i}",
                         namespace: 0,
                         deleted: i > 1)
        create(:revision,
               id: i,
               article_id: i,
               characters: 1000,
               views: 1000,
               user_id: 1,
               date: '2015-03-01'.to_date)
        course.articles << article
      end
      course.courses_users.each(&:update_cache)
      course.articles_courses.each(&:update_cache)
      course.update_cache

      expect(course.article_count).to eq(1)
      expect(course.view_sum).to eq(1000)
      expect(course.character_sum).to eq(1000)
    end
  end
end
