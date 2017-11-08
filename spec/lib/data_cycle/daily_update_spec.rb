# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/daily_update"

describe DailyUpdate do
  before do
    create(:course, start: '2015-03-20', end: 1.month.from_now,
                    flags: { salesforce_id: 'a0f1a9063a1Wyad' })
  end

  describe 'on initialization' do
    it 'calls lots of update routines' do
      expect(UserImporter).to receive(:update_users)
      expect(AssignedArticleImporter).to receive(:import_articles_for_assignments)
      expect(ArticlesCoursesCleaner).to receive(:rebuild_articles_courses)
      expect(RatingImporter).to receive(:update_all_ratings)
      expect(ArticleStatusManager).to receive(:update_article_status)
      expect(OresScoresBeforeAndAfterImporter).to receive(:import_all)
      expect(UploadImporter).to receive(:find_deleted_files)
      expect(UploadImporter).to receive(:import_uploads_for_current_users)
      expect(UploadImporter).to receive(:update_usage_count_by_course)
      expect(UploadImporter).to receive(:import_all_missing_urls)
      expect(PushCourseToSalesforce).to receive(:new)
      expect(Raven).to receive(:capture_message).and_call_original
      update = DailyUpdate.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/Updating Commons uploads/).any?).to eq(true)
    end

    it 'reports logs to sentry even when it errors out' do
      allow(Raven).to receive(:capture_message)
      allow(UploadImporter).to receive(:find_deleted_files).and_raise(StandardError)
      expect { DailyUpdate.new }.to raise_error(StandardError)
      expect(Raven).to have_received(:capture_message)
    end
  end

  describe '#wait_until_constant_update_finishes' do
    it 'returns immediately if no constant update is running' do
      allow_any_instance_of(DailyUpdate).to receive(:create_pid_file)
      allow_any_instance_of(DailyUpdate).to receive(:run_update)
      expect_any_instance_of(DailyUpdate).not_to receive(:sleep)
      DailyUpdate.new
    end

    it 'creates a sleep file and waits for a constant update to finish' do
      expect(File).to receive(:delete).with('tmp/batch_sleep_10.pid').and_call_original
      allow_any_instance_of(DailyUpdate).to receive(:create_pid_file) # for the main :daily pid
      allow_any_instance_of(DailyUpdate).to receive(:create_pid_file).with(:sleep).and_call_original
      allow_any_instance_of(DailyUpdate).to receive(:run_update)
      expect_any_instance_of(DailyUpdate).to receive(:sleep)
      allow_any_instance_of(DailyUpdate).to receive(:update_running?)
        .and_return(false, true, true, false)
      DailyUpdate.new
    end
  end

  context 'when a pid file is present' do
    it 'deletes the pid file for a non-running process' do
      allow_any_instance_of(DailyUpdate).to receive(:create_pid_file)
      allow_any_instance_of(DailyUpdate).to receive(:run_update)
      File.open('tmp/batch_update_constantly.pid', 'w') { |f| f.puts '123456789' }
      DailyUpdate.new
      expect(File.exist?('tmp/batch_update_constantly.pid')).to eq(false)
    end
  end
end
