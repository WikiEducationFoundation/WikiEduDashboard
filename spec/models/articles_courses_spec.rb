# == Schema Information
#
# Table name: articles_courses
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  article_id    :integer
#  course_id     :integer
#  view_count    :integer          default(0)
#  character_sum :integer          default(0)
#  new_article   :boolean          default(FALSE)
#

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
             username: 'Ragesoss')

      create(:course,
             id: 1,
             start: Time.zone.today - 1.month,
             end: Time.zone.today + 1.month,
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
             date: Time.zone.today,
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

  describe '.update_from_course' do
    before do
      create(:course, id: 1, start: 1.year.ago, end: 1.day.ago)
      create(:user, id: 1)
      create(:courses_user, user_id: 1, course_id: 1,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:article, id: 1, namespace: 0)
      create(:revision, article_id: 1, user_id: 1, date: 1.week.ago)
      create(:article, id: 2, namespace: 0)
      create(:revision, article_id: 1, user_id: 1, date: 2.years.ago)
      create(:article, id: 3, namespace: 1)
      create(:revision, article_id: 3, user_id: 1, date: 1.week.ago)
    end

    it 'creates new ArticlesCourses records from course revisions' do
      ArticlesCourses.update_from_course(Course.last)
      expect(ArticlesCourses.count).to eq(1)
    end

    it 'destroys ArticlesCourses that do not correspond to course revisions' do
      create(:articles_course, id: 500, article_id: 2, course_id: 1)
      create(:articles_course, id: 501, article_id: 2, course_id: 2)
      ArticlesCourses.update_from_course(Course.last)
      expect(ArticlesCourses.exists?(500)).to eq(false)
      expect(ArticlesCourses.exists?(501)).to eq(true)
    end
  end
end
