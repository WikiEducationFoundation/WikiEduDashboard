require 'rails_helper'

describe Article do
  describe '#url' do
    it 'should get the url for an article' do
      # Add an article
      article = build(:article,
                      id: 1,
                      title: 'Selfie',
                      namespace: 0,
                      views_updated_at: '2014-12-31'.to_date
      )

      # rubocop:disable Metrics/LineLength
      expect(article.url).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Selfie")

      sandbox = build(:article, namespace: 2, title: 'Ragesoss/sandbox')
      expect(sandbox.url).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/User:Ragesoss/sandbox")

      draft = build(:article, namespace: 118, title: 'My Awesome Draft!!!')
      expect(draft.url).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Draft:My_Awesome_Draft!!!")
      # rubocop:enable Metrics/LineLength
    end
  end

  describe '#update' do
    it 'should do a null update for an article' do
      VCR.use_cassette 'article/update' do
        # Add an article
        article = build(:article,
                        id: 1,
                        title: 'Selfie',
                        namespace: 0,
                        views_updated_at: '2014-12-31'.to_date
        )

        # Run update with no revisions
        article.update
        expect(article.views).to eq(0)

        # Add a revision and update again.
        build(:revision,
              article_id: 1,
              views: 10
        ).save
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
                        views_updated_at: '2014-12-31'.to_date
        )

        # Add a revision so that update_views has something to run on.
        build(:revision,
              article_id: 1
        ).save
        article.update_views
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
                      views_updated_at: '2014-12-31'.to_date
      )

      # Add a revision so that update_views has something to run on.
      build(:revision,
            article_id: 1
      ).save

      article.update_cache
      expect(article.revision_count).to be_kind_of(Integer)
      expect(article.character_sum).to be_kind_of(Integer)
    end
  end

  describe '.update_all_views' do
    it 'should get view data for all articles' do
      VCR.use_cassette 'article/update_all_views' do
        # Try it with no articles.
        Article.update_all_views

        # Add an article
        build(:article,
              id: 1,
              title: 'Wikipedia',
              namespace: 0,
              views_updated_at: '2014-12-31'.to_date
        ).save

        # Course, article-course, and revision are also needed.
        build(:course,
              id: 1,
              start: '2014-01-01'.to_date
        ).save
        build(:articles_course,
              id: 1,
              course_id: 1,
              article_id: 1
        ).save
        build(:revision,
              article_id: 1
        ).save

        # Update again with this article.
        Article.update_all_views
      end
    end
  end

  describe '.update_new_views' do
    it 'should get view data for new articles' do
      VCR.use_cassette 'article/update_new_views' do
        # Try it with no articles.
        Article.update_new_views

        # Add an article.
        build(:article,
              id: 1,
              title: 'Wikipedia',
              namespace: 0
        ).save

        # Course, article-course, and revision are also needed.
        build(:course,
              id: 1,
              start: '2014-01-01'.to_date
        ).save
        build(:articles_course,
              id: 1,
              course_id: 1,
              article_id: 1
        ).save
        build(:revision,
              article_id: 1
        ).save

        # Update again with this article.
        Article.update_new_views
      end
    end
  end

  describe '.update_all_caches' do
    it 'should caches for articles' do
      # Try it with no articles.
      Article.update_all_caches

      # Add an article.
      build(:article,
            id: 1,
            title: 'Selfie',
            namespace: 0
      ).save

      # Update again with this article.
      Article.update_all_caches
    end
  end

  describe '.update_ratings' do
    it 'should get latest ratings for articles' do
      VCR.use_cassette 'article/update_ratings' do
        # Add an article.
        create(:article,
               id: 1,
               title: 'Selfie',
               namespace: 0
        )

        possible_ratings = %w(fl fa a ga b c start stub list)

        # .update_ratings has a different flow for one rating vs. several,
        # so first we run an update with just one article.
        Article.update_new_ratings
        expect(possible_ratings).to include Article.all.first.rating

        create(:article,
               id: 2,
               title: 'A Clash of Kings',
               namespace: 0
        )
        Article.update_all_ratings
        expect(possible_ratings).to include Article.all.last.rating
      end
    end
  end

  describe 'deleted articles' do
    it 'should be marked as "deleted"' do
      course = create(:course,
                      end: '2016-12-31'.to_date
      )
      course.users << create(:user)
      create(:article,
             id: 1,
             title: 'Noarticle',
             namespace: 0
      )

      Article.update_articles_deleted
      expect(Article.find(1).deleted).to be true
    end

    it 'should not contribute to cached course values' do
      course = create(:course, end: '2016-12-31'.to_date)
      course.users << create(:user)
      CoursesUsers.update_all(role: 0)
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
