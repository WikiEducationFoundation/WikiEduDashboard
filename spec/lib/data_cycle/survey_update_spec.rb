require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/survey_update"

describe SurveyUpdate do
  describe 'on initialization' do
    it 'creates notifications, sends emails, and sends follow-ups' do
      expect(SurveyNotificationsManager).to receive(:create_notifications)
      update = SurveyUpdate.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/SurveyNotifications created/).any?).to eq(true)
      expect(sentry_logs.grep(/survey invitations sent/).any?).to eq(true)
      expect(sentry_logs.grep(/survey reminders sent/).any?).to eq(true)
    end
  end
end
