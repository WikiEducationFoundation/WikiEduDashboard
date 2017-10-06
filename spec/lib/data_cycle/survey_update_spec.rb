# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/survey_update"

describe SurveyUpdate do
  describe '#initialize' do
    it 'creates notifications, sends emails, and sends follow-ups' do
      expect(SurveyNotificationsManager).to receive(:create_notifications)
      update = SurveyUpdate.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/SurveyNotifications created/).any?).to eq(true)
      expect(sentry_logs.grep(/survey invitations sent/).any?).to eq(true)
      expect(sentry_logs.grep(/survey reminders sent/).any?).to eq(true)
    end
  end

  context 'when there are active surveys' do
    include_context 'survey_assignment'
    before do
      SurveyUpdate.new
    end

    it "sends emails for all SurveyNotifications with emails that haven\'t been sent" do
      expect(ActionMailer::Base.deliveries.count).to eq(2)
    end

    it 'sends emails to the users email address' do
      expect(ActionMailer::Base.deliveries.first.to.include?(@user.email)).to be(true)
      expect(ActionMailer::Base.deliveries.last.to.include?(@user2.email)).to be(true)
    end

    it 'sets SurveyNotification email_sent datetime attribute after sending' do
      expect(SurveyNotification.where(email_sent_at: nil).length).to eq(0)
    end

    it "only sends emails for notifications which haven't been dismissed" do
      SurveyUpdate.new
      expect(ActionMailer::Base.deliveries.count).to eq(2)
    end

    # This doesn't really test the effects of the error handling, but it does exercise it.
    it 're-raises common SMTP errors if they recur' do
      allow_any_instance_of(SurveyNotification).to receive(:send_email)
        .and_raise(Net::SMTPAuthenticationError)
      expect { SurveyUpdate.new }.to raise_error Net::SMTPAuthenticationError
    end

    private

    def recipients(recipient_position)
      deliveries = ActionMailer::Base.deliveries
      recipient_position == :first ? deliveries.first.to : deliveries.last.to
    end
  end
end
