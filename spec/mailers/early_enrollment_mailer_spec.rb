# frozen_string_literal: true

require 'rails_helper'

SEND_TO = 'wiki_expert@example.com'

describe EarlyEnrollmentMailer do
  let(:course) { create(:course, title: 'Ųnderwater básket-weaving') }

  let(:early_enrollment_alert) do
    create(:early_enrollment_alert, type: 'EarlyEnrollmentAlert', course:)
  end

  describe '.email' do
    before do
      allow(Features).to receive(:email?).and_return(true)

      # Mock the wiki_experts_email method to return a valid email
      allow(early_enrollment_alert).to receive(:wiki_experts_email).and_return([SEND_TO])
    end

    it 'generates an email to notify the Wiki Experts if a student joins a course early' do
      # Generate the email
      mail = described_class.email(early_enrollment_alert)

      # Ensure the email was generated
      expect(mail).not_to be_nil

      # Ensure the email subject is correct
      expect(mail.subject).to include(early_enrollment_alert.main_subject)

      # Ensure the email is being sent to the wiki experts
      expect(mail.to).to include(SEND_TO)
    end

    describe '.send_email' do
      it 'triggers email delivery' do
        allow(Features).to receive(:email?).and_return(true)
        expect_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
        described_class.send_email(early_enrollment_alert)
      end
    end
  end
end
