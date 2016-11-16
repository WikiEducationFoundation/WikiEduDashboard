# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/constant_update"

describe ConstantUpdate do
  describe 'on initialization' do
    it 'calls lots of update routines' do
      expect(LegacyCourseImporter).to receive(:update_all_courses)
      expect(UserImporter).to receive(:update_users)
      expect(CourseRevisionUpdater).to receive(:import_new_revisions)
      expect(AssignmentUpdater).to receive(:update_assignment_article_ids_and_titles)
      expect_any_instance_of(RevisionScoreImporter).to receive(:update_revision_scores)
      expect(PlagiabotImporter).to receive(:find_recent_plagiarism)
      expect(Article).to receive(:update_all_caches)
      expect(ArticlesCourses).to receive(:update_all_caches)
      expect(CoursesUsers).to receive(:update_all_caches)
      expect(Course).to receive(:update_all_caches)
      expect(StudentGreeter).to receive(:greet_all_ungreeted_students)
      expect(ArticlesForDeletionMonitor).to receive(:create_alerts_for_course_articles)
      expect_any_instance_of(CourseAlertManager).to receive(:create_no_students_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_untrained_students_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_productive_course_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_active_course_alerts)
      expect_any_instance_of(CourseAlertManager).to receive(:create_deleted_uploads_alerts)
      expect_any_instance_of(CourseAlertManager)
        .to receive(:create_continued_course_activity_alerts)
      expect_any_instance_of(SurveyResponseAlertManager).to receive(:create_alerts)
      expect(Raven).to receive(:capture_message).and_call_original
      update = ConstantUpdate.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/Importing revisions and articles/).any?).to eq(true)
    end
  end
end
