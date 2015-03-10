require 'rails_helper'

require 'rails_helper'

describe ArticlesCourses, type: :model do
  describe '.update_all_caches' do
    it 'should update data for article-course relationships' do
      # Make an article-course.
      article_course = build(:articles_course,
                             id: 1,
                             article_id: 1,
                             course_id: 1
      )
      article_course.save

      # Add a user, a course, and an article.
      build(:user,
            id: 1,
            wiki_id: 'Ragesoss'
      ).save

      build(:course,
            id: 1,
            start: '2015-01-01'.to_date,
            end: '2015-07-01'.to_date,
            title: 'Underwater basket-weaving'
      ).save

      build(:article,
            id: 1,
            title: 'Selfie',
            namespace: 0
      ).save

      # Run a cache update without any revisions.
      ArticlesCourses.update_all_caches

      # Add a revision.
      build(:revision,
            id: 1,
            user_id: 1,
            article_id: 1,
            date: '2015-03-01'.to_date,
            characters: 9000,
            new_article: 1,
            views: 1234
      ).save

      # Assign the article to the user.
      build(:assignment,
            course_id: 1,
            user_id: 1,
            article_id: 1,
            article_title: 'Selfie'
      ).save

      # Make a course-user and save it.
      build(:courses_user,
            id: 1,
            course_id: 1,
            user_id: 1,
            assigned_article_title: 'Selfie'
      ).save

      # Run the cache update again with an existing revision.
      ArticlesCourses.update_all_caches

      # FIXME: Make the view count, new article status and character sum
      # update so that the view_count, new_article, and character_sum values
      # reflect the revision above.

      expect(article_course.view_count).to be_kind_of(Integer)
      expect(article_course.new_article).to be_boolean
      expect(article_course.character_sum).to be_kind_of(Integer)
    end
  end
end
