# frozen_string_literal: true

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
require "#{Rails.root}/lib/articles_courses_cleaner"

describe ArticlesCourses, type: :model do
  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:course) { create(:course, start: 1.month.ago, end: 1.month.from_now) }

  describe '.update_all_caches' do
    it 'should update data for article-course relationships' do
      # Make an ArticlesCourses record
      article_course = create(:articles_course, article: article, course: course)
      # Add user to course
      create(:courses_user, course: course, user: user)

      # Run a cache update without any revisions.
      ArticlesCourses.update_all_caches(article_course)

      # Add a revision.
      create(:revision,
             user: user,
             article: article,
             date: Time.zone.today,
             characters: 9000,
             new_article: 1,
             views: 1234)

      # Deleted revision, which should not count towards stats.
      create(:revision,
             user: user,
             article: article,
             date: Time.zone.today,
             characters: 9001,
             deleted: true,
             views: 2345)

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
    let(:course) { create(:course, start: 1.year.ago, end: 1.day.ago) }
    let(:another_course) { create(:course, slug: 'something else') }
    let(:user) { create(:user) }
    let(:article) { create(:article, namespace: 0) }
    let(:article2) { create(:article, title: 'Second Article', namespace: 0) }
    let(:talk_page) { create(:article, title: 'Talk page', namespace: 1) }

    before do
      create(:courses_user, user: user, course: course,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:revision, article: article, user: user, date: 1.week.ago,
                        system: true, new_article: true)
      create(:revision, article: article, user: user, date: 6.days.ago)
      # old revision before course
      create(:revision, article: article2, user: user, date: 2.years.ago)
      create(:revision, article: talk_page, user: user, date: 1.week.ago)
    end

    it 'creates new ArticlesCourses records from course revisions' do
      ArticlesCourses.update_from_course(Course.last)
      expect(ArticlesCourses.count).to eq(1)
      # Should be counted as new even though the first edit was a system edit.
      ArticlesCourses.last.update_cache
      expect(ArticlesCourses.last.new_article).to eq(true)
    end

    it 'destroys ArticlesCourses that do not correspond to course revisions' do
      create(:articles_course, id: 500, article: article2, course: course)
      create(:articles_course, id: 501, article: article2, course: another_course)
      ArticlesCourses.update_from_course(course)
      expect(ArticlesCourses.exists?(500)).to eq(false)
      # only destroys for the course specified, not other recoreds that also
      # don't correspond to their own course.
      expect(ArticlesCourses.exists?(501)).to eq(true)
      ArticlesCourses.update_from_course(another_course)
      expect(ArticlesCourses.exists?(501)).to eq(false)
    end
  end
end
