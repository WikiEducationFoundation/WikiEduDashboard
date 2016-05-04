require 'rails_helper'
# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss

describe 'article:update_views_all_time' do
  include_context 'rake'

  describe 'update_views_all_time' do
    it 'calls ViewImporter to update views' do
      expect(ViewImporter).to receive(:update_all_views).with(true)
      subject.invoke
    end
  end

  describe 'reset_articles_courses' do
    it 'calls Cleaners.remove_bad_articles_courses' do
      expect(Cleaners).to receive(:remove_bad_articles_courses)
      rake['article:reset_articles_courses'].invoke
    end
  end

  describe 'rebuild_articles_courses' do
    it 'calls Cleaners.rebuild_articles_courses' do
      expect(Cleaners).to receive(:rebuild_articles_courses)
      rake['article:rebuild_articles_courses'].invoke
    end
  end

  describe 'repair_orphan_revisions' do
    it 'calls RevisionsCleaner.repair_orphan_revisions' do
      expect(RevisionsCleaner).to receive(:repair_orphan_revisions)
      rake['article:repair_orphan_revisions'].invoke
    end
  end

  describe 'import_assigned_articles' do
    it 'calls AssignedArticleImporter.import_articles_for_assignments' do
      expect(AssignedArticleImporter).to receive(:import_articles_for_assignments)
      rake['article:import_assigned_articles'].invoke
    end
  end
end
