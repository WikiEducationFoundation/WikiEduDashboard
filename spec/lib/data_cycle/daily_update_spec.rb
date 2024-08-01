# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/daily_update"

describe DailyUpdate do
  before do
    course = create(:course, start: '2015-03-20', end: 1.month.from_now,
                             flags: { salesforce_id: 'a0f1a9063a1Wyad' })
    course.campaigns << Campaign.first
    old_course = create(:course, slug: 'old', start: '2015-03-20', end: '2015-04-20',
                                 flags: { salesforce_id: 'b0f1a9063a1Wyad' })
    old_course.campaigns << Campaign.first
    stub_wiki_validation
  end

  describe 'on initialization' do
    it 'calls lots of update routines' do
      worker_double = class_double(WikiDiscouragedArticleWorker)
      expect(UserImporter).to receive(:update_users)
      expect(AssignedArticleImporter).to receive(:import_articles_for_assignments)
      # TODO: modify this when implementing the rebuilding articles courses without revisions
      # expect(ArticlesCoursesCleaner).to receive(:rebuild_articles_courses)
      expect(RatingImporter).to receive(:update_all_ratings)
      expect(UploadImporter).to receive(:find_deleted_files)
      expect_any_instance_of(OverdueTrainingAlertManager).to receive(:create_alerts)
      expect(PushCourseToSalesforce).to receive(:new)
      expect(UpdateCourseFromSalesforce).to receive(:new)
      expect(Sentry).to receive(:capture_message).and_call_original
      expect(WikiDiscouragedArticleWorker).to receive(:set).with(queue: described_class::QUEUE)
                                          .and_return(worker_double)
      expect(worker_double).to receive(:perform_async)
      update = described_class.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/Pushing course data to Salesforce/).any?).to eq(true)
    end

    it 'reports logs to sentry even when it errors out' do
      allow(Sentry).to receive(:capture_message)
      allow(UploadImporter).to receive(:find_deleted_files).and_raise(StandardError)
      expect { described_class.new }.to raise_error(StandardError)
      expect(Sentry).to have_received(:capture_message)
    end
  end

  context 'when a pid file is present' do
    it 'deletes the pid file for a non-running process' do
      allow_any_instance_of(described_class).to receive(:create_pid_file)
      allow_any_instance_of(described_class).to receive(:run_update)
      File.open('tmp/batch_update_daily.pid', 'w') { |f| f.puts '123456789' }
      described_class.new
      expect(File.exist?('tmp/batch_update_daily.pid')).to eq(false)
    end
  end
end
