require 'rails_helper'
require "#{Rails.root}/lib/course_alert_manager"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe CourseAlertManager do
  describe '#create_no_students_alerts' do
    let(:course) { create(:course, timeline_start: 16.days.ago) }
    let(:admin) { create(:admin, email: 'staff@wikiedu.org') }
    let!(:courses_user) do
      create(:courses_user,
             course_id: course.id,
             user_id: admin.id,
             role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    end
    let(:subject) { CourseAlertManager.new.create_no_students_alerts }

    it 'creates an Alert record and emails a greeter' do
      expect_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      subject
      expect(Alert.count).to eq(1)
      expect(Alert.last.email_sent_at).not_to be_nil
    end

    it 'does not create a second Alert for the same course' do
      Alert.create(type: 'NoEnrolledStudentsAlert', course_id: course.id)
      expect(Alert.count).to eq(1)
      subject
      expect(Alert.count).to eq(1)
    end
  end
end
