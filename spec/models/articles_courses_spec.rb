require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/cleaners"

describe ArticlesCourses, type: :model do
  describe '.update_all_caches' do
    it 'should update data for article-course relationships' do
      # Make an article-course.
      article_course = create(:articles_course,
                              id: 1,
                              article_id: 1,
                              course_id: 1)

      # Add a user, a course, and an article.
      create(:user,
             id: 1,
             wiki_id: 'Ragesoss')

      create(:course,
             id: 1,
             start: Date.today - 1.month,
             end: Date.today + 1.month,
             title: 'Underwater basket-weaving')

      create(:article,
             id: 1,
             title: 'Selfie',
             namespace: 0)

      # Run a cache update without any revisions.
      ArticlesCourses.update_all_caches(article_course)

      # Add a revision.
      create(:revision,
             id: 1,
             user_id: 1,
             article_id: 1,
             date: Date.today,
             characters: 9000,
             new_article: 1,
             views: 1234)

      # Assign the article to the user.
      create(:assignment,
             course_id: 1,
             user_id: 1,
             article_id: 1,
             article_title: 'Selfie')

      # Make a course-user and save it.
      create(:courses_user,
             id: 1,
             course_id: 1,
             user_id: 1,
             assigned_article_title: 'Selfie')

      # Run the cache update again with an existing revision.
      ArticlesCourses.update_all_caches

      # Fetch the created ArticlesCourses entry
      article_course = ArticlesCourses.all.first

      expect(article_course.view_count).to eq(1234)
      expect(article_course.new_article).to be true
      expect(article_course.character_sum).to eq(9000)
    end
  end

  describe '.remove_bad_articles_courses' do
    it 'should remove ArticlesCourses that do not belong' do
      create(:course,
             id: 1,
             start: Date.today - 1.month,
             end: Date.today + 1.month,
             title: 'Underwater basket-weaving')
      create(:user,
             id: 1)
      # A user who is not a student, so they should not have ArticlesCourses
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: 2)
      create(:article,
             id: 1)
      create(:revision,
             user_id: 1,
             article_id: 1,
             date: Date.today)
      # An ArticlesCourse that should be removed
      create(:articles_course,
             course_id: 1,
             article_id: 1)

      Cleaners.remove_bad_articles_courses
      expect(ArticlesCourses.all.count).to eq(0)
    end
  end
end
