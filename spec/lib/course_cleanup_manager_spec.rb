# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_cleanup_manager"

describe CourseCleanupManager do
  let!(:user) { create(:user) }
  let!(:user2) { create(:trained) }
  let!(:course) { create(:course) }
  let!(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
  let!(:courses_user2) { create(:courses_user, course_id: course.id, user_id: user2.id) }
  let!(:article) { create(:article) }
  let!(:article2) { create(:article) }

  let!(:revision) do
    create(:revision, date: course.start + 1.day, article_id: article.id, user_id: user.id)
  end
  let!(:revision2) do
    create(:revision, date: course.start + 1.day, article_id: article.id, user_id: user2.id)
  end
  let!(:revision3) do
    create(:revision, date: course.start + 1.day, article_id: article2.id, user_id: user.id)
  end

  before do
    ArticlesCourses.update_from_course(course)
  end

  describe '#cleanup_articles' do
    it 'only deletes ArticlesCourses that belong solely to the removed user' do
      expect(course.articles.count).to eq(2)
      CourseCleanupManager.new(course, user).cleanup_articles
      expect(course.articles.count).to eq(1)
    end
  end
end
