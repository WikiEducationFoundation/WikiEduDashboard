# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/articles_courses_cleaner"

describe ArticlesCoursesCleaner do
  describe '.remove_bad_articles_courses' do
    it 'remove ArticlesCourses that do not belong' do
      create(:course,
             id: 1,
             start: Time.zone.today - 1.month,
             end: Time.zone.today + 1.month,
             title: 'Underwater basket-weaving')
      create(:user,
             id: 1)
      create(:user,
             id: 2,
             username: 'user2')
      # A user who is not a student, so they should not have ArticlesCourses
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: 2)
      create(:courses_user,
             course_id: 1,
             user_id: 2,
             role: 0)
      create(:article,
             id: 1)
      create(:revision,
             user_id: 1,
             article_id: 1,
             date: Time.zone.today)
      # An ArticlesCourse that should be removed
      create(:articles_course,
             course_id: 1,
             article_id: 1)

      described_class.remove_bad_articles_courses
      expect(ArticlesCourses.all.count).to eq(0)
      # Now recreate it where another classmate touched it
      create(:revision,
             user_id: 2,
             article_id: 1,
             date: Time.zone.today)
      create(:articles_course,
             course_id: 1,
             article_id: 1)
      described_class.remove_bad_articles_courses
      expect(ArticlesCourses.all.count).to eq(1)
    end
  end

  describe '.rebuild_articles_courses' do
    it 'creates ArticlesCourses for current students' do
      create(:course,
             id: 1,
             start: 1.month.ago,
             end: Time.zone.today + 1.year)
      create(:course,
             id: 2,
             slug: 'foo/course2',
             start: 1.month.ago,
             end: Time.zone.today + 1.year)
      create(:revision,
             mw_rev_id: 661324615,
             article_id: 46640378,
             user_id: 1,
             date: 1.day.ago)
      create(:article,
             id: 46640378,
             namespace: 0)
      create(:user,
             id: 1,
             username: 'Rothscak')
      create(:courses_user,
             course_id: 1,
             user_id: 1)
      described_class.rebuild_articles_courses
      articles_for_course = ArticlesCourses.where(course_id: 1)
      expect(articles_for_course.count).to eq(1)
    end
  end
end
