require 'rails_helper'
# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss

describe 'batch:update_constantly' do
  include_context 'rake'

  describe 'update_constantly' do
    it 'calls lots of update routines' do
      expect(LegacyCourseImporter).to receive(:update_all_courses)
      expect(UserImporter).to receive(:update_users)
      expect(RevisionImporter).to receive(:update_all_revisions)
      expect_any_instance_of(RevisionScoreImporter).to receive(:update_revision_scores)
      expect(PlagiabotImporter).to receive(:find_recent_plagiarism)
      expect(Article).to receive(:update_all_caches)
      expect(ArticlesCourses).to receive(:update_all_caches)
      expect(CoursesUsers).to receive(:update_all_caches)
      expect(Course).to receive(:update_all_caches)
      expect(StudentGreeter).to receive(:greet_all_ungreeted_students)
      expect(Raven).to receive(:capture_message)
      subject.invoke
    end
  end

  describe 'update_daily' do
    it 'calls lots of update routines' do
      expect(AssignedArticleImporter).to receive(:import_articles_for_assignments)
      expect(Cleaners).to receive(:rebuild_articles_courses)
      expect(RatingImporter).to receive(:update_all_ratings)
      expect(ArticleStatusManager).to receive(:update_article_status)
      expect(ViewImporter).to receive(:update_all_views)
      expect(UploadImporter).to receive(:find_deleted_files)
      expect(UploadImporter).to receive(:import_all_uploads)
      expect(UploadImporter).to receive(:update_usage_count)
      expect(UploadImporter).to receive(:import_urls_in_batches)
      expect(CacheUpdater).to receive(:update_all_caches)
      expect(Raven).to receive(:capture_message)
      rake['batch:update_daily'].invoke
    end
  end

  describe 'pause' do
    it 'creates a pause file' do
      pause_file = 'tmp/batch_pause.pid'
      rake['batch:pause'].invoke
      expect(File.exist?(pause_file)).to eq(true)
      File.delete pause_file
    end
  end

  describe 'resume' do
    it 'deletes a pause file' do
      pause_file = 'tmp/batch_pause.pid'
      File.open(pause_file, 'w') { |f| f.puts 'ohai' }
      rake['batch:resume'].invoke
      expect(File.exist?(pause_file)).to eq(false)
    end
  end
end
