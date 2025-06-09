# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_namespaces_manager"

describe ArticleNamespacesManager do
  let(:course) { create(:course, start: 1.year.ago, end: 1.year.from_now) }
  let(:wiki) { course.home_wiki }
  let(:moved_to_mainspace) { 2.weeks.ago }
  let(:first_revision) { 2.months.ago }
  let(:mainspace_article) { create(:article, namespace: 0, updated_at: moved_to_mainspace) }
  let(:subject) { described_class.new(course) }

  context 'when an article moved from userspace to mainspace' do
    before do
      create(:articles_course, course:, article_id: mainspace_article.id,
             created_at: moved_to_mainspace)
      create(:course_wiki_timeslice, course:, wiki:, start: first_revision.beginning_of_day)
      create(:course_wiki_timeslice, course:, wiki:, start: moved_to_mainspace.beginning_of_day)
      create(:article_course_timeslice, course:, article_id: mainspace_article.id,
              start: first_revision.beginning_of_day, created_at: first_revision.beginning_of_day)
      create(:article_course_timeslice, course:, article_id: mainspace_article.id,
              start: moved_to_mainspace.beginning_of_day,
              created_at: moved_to_mainspace.beginning_of_day)
    end

    it 'resets timeslices for article' do
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
      expect(ArticlesCourses.where(article_id: mainspace_article.id).count).to eq(1)
      expect(ArticleCourseTimeslice.where(article_id: mainspace_article.id).count).to eq(2)
      subject
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(2)
      expect(ArticlesCourses.where(article_id: mainspace_article.id)).to be_empty
      expect(ArticleCourseTimeslice.where(article_id: mainspace_article.id).count).to eq(0)
    end
  end
end
