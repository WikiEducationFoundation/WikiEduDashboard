# frozen_string_literal: true

require 'rails_helper'

SUBJECT = 'Test Subject'

describe InstructorNotificationMailer do
  let(:course) { create(:course) }
  let(:admin) { create(:admin, email: 'admin@wikiedu.org') }
  let(:instructor) { create(:user, email: 'instructor@wikiedu.org') }
  let!(:courses_user) do
    create(:courses_user, course_id: course.id, user_id: instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  let(:instructor_notification_alert) do
    create(:instructor_notification_alert, type: 'InstructorNotificationAlert',
course_id: course.id, message: 'Test Email Content', user: admin, subject: SUBJECT)
    Alert.last
  end

  describe '.email' do
    let(:mail) { described_class.email(instructor_notification_alert) }

    it 'delivers an email to the instructor and CCs Wiki Ed staff' do
      allow(Features).to receive(:email?).and_return(true)
      expect(mail.subject).to include(SUBJECT)
      expect(mail.to).to include(instructor.email)
      expect(mail.body).to include('Test Email Content')
      expect(mail.reply_to).to include(admin.email)
    end
  end
end
