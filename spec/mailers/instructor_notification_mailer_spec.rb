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
          course_id: course.id, message: 'Test Email Content', user: admin,
          details: { subject: SUBJECT, bcc_to_salesforce: true })
    Alert.last
  end

  describe '.email' do
    let(:mail) { described_class.email(instructor_notification_alert) }

    before do
      allow(Features).to receive(:email?).and_return(true)
    end

    it 'generates an email to the instructor and CCs Wiki Ed staff' do
      allow(Features).to receive(:email?).and_return(true)
      expect(mail.subject).to include(SUBJECT)
      expect(mail.to).to include(instructor.email)
      expect(mail.body).to include('Test Email Content')
      expect(mail.reply_to).to include(admin.email)
    end
  end

  context 'when bcc_to_salesforce is true' do
    before do
      instructor_notification_alert.update(
        details: { subject: SUBJECT, bcc_to_salesforce: true }
      )
    end

    it 'includes the BCC field' do
      mail = described_class.email(instructor_notification_alert, true)
      expect(mail.bcc).to include(ENV['SALESFORCE_BCC_EMAIL'])
    end
  end

  context 'when bcc_to_salesforce is not included' do
    before do
      instructor_notification_alert.update(
        details: { subject: SUBJECT }
      )
    end

    it 'does not include the BCC field' do
      mail = described_class.email(instructor_notification_alert, false)
      expect(mail.bcc).to be_empty
    end
  end

  describe '.send_email' do
    it 'triggers email delivery' do
      ActionMailer::Base.deliveries.clear

      allow(Features).to receive(:email?).and_return(true)
      described_class.send_email(instructor_notification_alert, true)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to include(SUBJECT)
      expect(ActionMailer::Base.deliveries.first.to).to include(instructor.email)
      expect(ActionMailer::Base.deliveries.first.reply_to).to include(admin.email)
    end
  end
end