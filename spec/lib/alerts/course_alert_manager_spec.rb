# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/course_alert_manager"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe CourseAlertManager do
  let(:subject) { described_class.new }

  let(:course) do
    create(:course, start: course_start,
                    timeline_start: course_start,
                    timeline_end: course_end,
                    end: course_end,
                    weekdays: '0101010',
                    expected_students:,
                    user_count:)
  end
  let(:course_start) { 16.days.ago }
  let(:course_end) { 1.month.from_now }
  let(:admin) { create(:admin, email: 'staff@wikiedu.org') }
  let(:user) { create(:user) }
  let(:expected_students) { nil }
  let(:user_count) { 1 }

  let(:enroll_admin) do
    create(:courses_user,
           course:,
           user: admin,
           role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end
  let(:enroll_student) do
    create(:courses_user,
           course:,
           user:,
           role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  before do
    TrainingModule.load_all
    enroll_admin
  end

  describe '.generate_course_alerts' do
    it 'runs without error' do
      described_class.generate_course_alerts
    end
  end

  describe '#create_no_students_alerts' do
    before do
      # These alerts are only created if the course is approved.
      create(:campaigns_course, course:, campaign: Campaign.first)
    end

    it 'creates an Alert record and emails a greeter' do
      expect_any_instance_of(NoEnrolledStudentsAlertMailer)
        .to receive(:email).and_return(mock_mailer)
      subject.create_no_students_alerts
      expect(Alert.count).to eq(1)
      expect(Alert.last.email_sent_at).not_to be_nil
    end

    it 'does not create a second Alert for the same course' do
      Alert.create(type: 'NoEnrolledStudentsAlert', course_id: course.id)
      expect(Alert.count).to eq(1)
      subject.create_no_students_alerts
      expect(Alert.count).to eq(1)
    end
  end

  describe '#create_over_enrollment_alerts' do
    context 'when there is significant over-enrollment' do
      let(:user_count) { 50 }
      let(:expected_students) { 25 }

      it 'creates an alert' do
        subject.create_over_enrollment_alerts
        expect(Alert.count).to eq(1)
      end

      it 'does not create a second Alert for the same course' do
        Alert.create(type: 'OverEnrollmentAlert', course:)
        expect(Alert.count).to eq(1)
        subject.create_over_enrollment_alerts
        expect(Alert.count).to eq(1)
      end
    end

    context 'when there is slight over-enrollment' do
      let(:user_count) { 50 }
      let(:expected_students) { 49 }

      it 'does not create an alert' do
        subject.create_over_enrollment_alerts
        expect(Alert.count).to eq(0)
      end
    end

    context 'when there are more than 100 students' do
      let(:user_count) { 101 }
      let(:expected_students) { 101 }

      it 'creates an alert' do
        subject.create_over_enrollment_alerts
        expect(Alert.count).to eq(1)
      end
    end
  end

  describe '#create_untrained_students_alerts' do
    let(:course_start) { 2.months.ago }

    context 'when a course has no students' do
      it 'does not create an alert' do
        expect(course.students.count).to eq(0)
        subject.create_untrained_students_alerts
        expect(Alert.count).to eq(0)
      end
    end

    context 'when a course has no training modules' do
      before do
        enroll_student
        course.update_cache
      end

      it 'does not create an alert' do
        expect(course.user_count).to eq(1)
        subject.create_untrained_students_alerts
        expect(Alert.count).to eq(0)
      end
    end

    context 'when a course has a training module that is long overdue' do
      before do
        week = Week.new
        week.blocks << Block.new(training_module_ids: [1, 2, 3])
        course.weeks << week
        create(:courses_user,
               course:,
               user:,
               role: CoursesUsers::Roles::STUDENT_ROLE)
        create(:campaigns_course, course:, campaign: Campaign.first)
        course.update_cache
      end

      it 'creates an alert' do
        expect_any_instance_of(UntrainedStudentsAlertMailer)
          .to receive(:email).and_return(mock_mailer)
        subject.create_untrained_students_alerts
        expect(Alert.count).to eq(1)
        expect(Alert.last.email_sent_at).not_to be_nil
      end
    end
  end

  describe '#create_productive_course_alerts' do
    it 'calls "create_alerts" on ProductiveCourseAlertManager' do
      expect_any_instance_of(ProductiveCourseAlertManager).to receive(:create_alerts)
      subject.create_productive_course_alerts
    end
  end

  describe '#create_continued_course_activity_alerts' do
    it 'calls "create_alerts" on ContinuedCourseActivityAlertManager' do
      expect_any_instance_of(ContinuedCourseActivityAlertManager).to receive(:create_alerts)
      subject.create_continued_course_activity_alerts
    end
  end

  describe '#create_active_course_alerts' do
    it 'calls "create_alerts" on ActiveCourseAlertManager' do
      expect_any_instance_of(ActiveCourseAlertManager).to receive(:create_alerts)
      subject.create_active_course_alerts
    end
  end

  describe '#create_deleted_uploads_alerts' do
    it 'calls "create_alerts" on DeletedUploadsAlertManager' do
      expect_any_instance_of(DeletedUploadsAlertManager).to receive(:create_alerts)
      subject.create_deleted_uploads_alerts
    end
  end
end
