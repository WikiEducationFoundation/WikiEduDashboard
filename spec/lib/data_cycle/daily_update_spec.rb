# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/daily_update"

describe DailyUpdate do
  describe 'on initialization' do
    it 'calls lots of update routines' do
      expect(AssignedArticleImporter).to receive(:import_articles_for_assignments)
      expect(ArticlesCoursesCleaner).to receive(:rebuild_articles_courses)
      expect(RatingImporter).to receive(:update_all_ratings)
      expect(ArticleStatusManager).to receive(:update_article_status)
      expect(ViewImporter).to receive(:update_all_views)
      expect(UploadImporter).to receive(:find_deleted_files)
      expect(UploadImporter).to receive(:import_all_uploads)
      expect(UploadImporter).to receive(:update_usage_count_by_course)
      expect(UploadImporter).to receive(:import_urls_in_batches)
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
      allow_any_instance_of(DailyUpdate).to receive(:create_pid_file)
      allow_any_instance_of(DailyUpdate).to receive(:run_update)
      allow_any_instance_of(DailyUpdate).to receive(:daily_update_running?).and_return(false)

      expect_any_instance_of(DailyUpdate).to receive(:sleep)
      allow_any_instance_of(DailyUpdate).to receive(:constant_update_running?)
        .and_return(true, true, false)
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
