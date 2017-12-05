# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/constant_update"

describe ConstantUpdate do
  describe 'on initialization' do
    before do
      create(:course, start: '2015-03-20', end: '2015-03-31', needs_update: true,
                      flags: { salesforce_id: 'a0f1a9063a1Wyad' })
    end

    it 'calls lots of update routines and resets :needs_update flag on courses' do
      expect(CourseRevisionUpdater).to receive(:import_new_revisions_concurrently)
      expect(AssignmentUpdater).to receive(:update_assignment_article_ids_and_titles)
      expect_any_instance_of(RevisionScoreImporter).to receive(:update_revision_scores)
      expect(PlagiabotImporter).to receive(:find_recent_plagiarism)
      expect(UploadImporter).to receive(:import_all_uploads)
      expect(UploadImporter).to receive(:update_usage_count_by_course)
      expect(ArticlesCourses).to receive(:update_all_caches)
      expect(CoursesUsers).to receive(:update_all_caches_concurrently)
      expect(Course).to receive(:update_all_caches_concurrently)
      expect(StudentGreetingChecker).to receive(:check_all_ungreeted_students)
      expect(ArticlesForDeletionMonitor).to receive(:create_alerts_for_course_articles)
      expect(DiscretionarySanctionsMonitor).to receive(:create_alerts_for_course_articles)
      expect(DYKNominationMonitor).to receive(:create_alerts_for_course_articles)
      expect_any_instance_of(CourseAlertManager).to receive(:create_no_students_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_untrained_students_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_productive_course_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_active_course_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_deleted_uploads_alerts)
      expect_any_instance_of(CourseAlertManager)
        .to receive(:create_continued_course_activity_alerts)
      expect_any_instance_of(SurveyResponseAlertManager).to receive(:create_alerts)
      expect(UpdateLog).to receive(:log_update)
      expect(Raven).to receive(:capture_message).and_call_original
      update = ConstantUpdate.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/Importing revisions and articles/).any?).to eq(true)
      expect(Course.where(needs_update: true).count).to eq(0)
    end

    it 'reports logs to sentry even when it errors out' do
      allow(Raven).to receive(:capture_message)
      allow(CourseRevisionUpdater).to receive(:import_new_revisions_concurrently)
        .and_raise(StandardError)
      expect { ConstantUpdate.new }.to raise_error(StandardError)
      expect(Raven).to have_received(:capture_message)
    end
  end
end
