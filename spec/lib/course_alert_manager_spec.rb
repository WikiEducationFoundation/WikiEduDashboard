require 'rails_helper'
require "#{Rails.root}/lib/course_alert_manager"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe CourseAlertManager do
  let(:subject) { CourseAlertManager.new }

  let(:course) do
    create(:course, start: course_start,
                    timeline_start: course_start,
                    timeline_end: course_end,
                    end: course_end,
                    weekdays: '0101010')
  end
  let(:course_start) { 16.days.ago }
  let(:course_end) { 1.month.from_now }
  let(:admin) { create(:admin, email: 'staff@wikiedu.org') }
  let(:user) { create(:user) }

  let(:enroll_admin) do
    create(:courses_user,
           course_id: course.id,
           user_id: admin.id,
           role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end
  let(:enroll_student) do
    create(:courses_user,
           course_id: course.id,
           user_id: user.id,
           role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  before :each do
    enroll_admin
  end

  describe '#create_no_students_alerts' do
    it 'creates an Alert record and emails a greeter' do
      expect_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
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

  describe '#create_untrained_students_alerts' do
    let(:course_start) { 1.month.ago }

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
               course_id: course.id,
               user_id: user.id,
               role: CoursesUsers::Roles::STUDENT_ROLE)
        course.update_cache
      end
      it 'creates an alert' do
        expect_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
        subject.create_untrained_students_alerts
        expect(Alert.count).to eq(1)
        expect(Alert.last.email_sent_at).not_to be_nil
      end
    end
  end
end
