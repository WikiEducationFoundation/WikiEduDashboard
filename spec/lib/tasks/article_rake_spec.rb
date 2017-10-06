# frozen_string_literal: true

require 'rails_helper'
# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss

describe 'article:reset_articles_courses' do
  include_context 'rake'

  describe 'reset_articles_courses' do
    it 'calls Cleaners.remove_bad_articles_courses' do
      expect(ArticlesCoursesCleaner).to receive(:remove_bad_articles_courses)
      rake['article:reset_articles_courses'].invoke
    end
  end

  describe 'rebuild_articles_courses' do
    it 'calls Cleaners.rebuild_articles_courses' do
      expect(ArticlesCoursesCleaner).to receive(:rebuild_articles_courses)
      rake['article:rebuild_articles_courses'].invoke
    end
  end

  describe 'import_assigned_articles' do
    it 'calls AssignedArticleImporter.import_articles_for_assignments' do
      expect(AssignedArticleImporter).to receive(:import_articles_for_assignments)
      rake['article:import_assigned_articles'].invoke
    end
  end
end
