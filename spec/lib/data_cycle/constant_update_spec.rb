# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/data_cycle/constant_update')

describe ConstantUpdate do
  describe 'on initialization' do
    before do
      create(:course, start: '2015-03-20', end: '2015-03-31', needs_update: true,
                      flags: { salesforce_id: 'a0f1a9063a1Wyad' })
    end

    it 'calls lots of update routines' do
      expect(AssignmentUpdater).to receive(:update_assignment_article_ids_and_titles)
      expect(PlagiabotImporter).to receive(:find_recent_plagiarism)
      expect(StudentGreetingChecker).to receive(:check_all_ungreeted_students)
      expect(ArticlesForDeletionMonitor).to receive(:create_alerts_for_course_articles)
      expect(DiscretionarySanctionsMonitor).to receive(:create_alerts_for_course_articles)
      expect(HighQualityArticleMonitor).to receive(:create_alerts_for_course_articles)
      expect(ProtectedArticleMonitor).to receive(:create_alerts_for_assigned_articles)
      expect(DYKNominationMonitor).to receive(:create_alerts_for_course_articles)
      expect(GANominationMonitor).to receive(:create_alerts_for_course_articles)
      expect(BlockedUserMonitor).to receive(:create_alerts_for_recently_blocked_users)
      expect(DeUserfyingEditAlertMonitor).to receive(:create_alerts_for_deuserfying_edits)
      expect(MedicineArticleMonitor).to receive(:create_alerts_for_no_med_training_for_course)

      expect_any_instance_of(CourseAlertManager).to receive(:create_no_students_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_untrained_students_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_productive_course_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_active_course_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_deleted_uploads_alerts)
      expect_any_instance_of(CourseAlertManager)
        .to receive(:create_continued_course_activity_alerts)
      expect_any_instance_of(SurveyResponseAlertManager).to receive(:create_alerts)
      expect(UpdateLogger).to receive(:update_settings_record)
      expect(Sentry).to receive(:capture_message).and_call_original
      update = described_class.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/Generating AfD alerts/).any?).to eq(true)
    end

    it 'reports logs to sentry even when it errors out' do
      allow(Sentry).to receive(:capture_message)
      allow(PlagiabotImporter).to receive(:find_recent_plagiarism)
        .and_raise(StandardError)
      expect { described_class.new }.to raise_error(StandardError)
      expect(Sentry).to have_received(:capture_message).with('Constant update failed.', anything)
    end
  end
end
