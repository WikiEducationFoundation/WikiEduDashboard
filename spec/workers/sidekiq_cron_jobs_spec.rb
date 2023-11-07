# frozen_string_literal: true
require 'rails_helper'
require Rails.root.join('app/workers/daily_update_worker')
require Rails.root.join('app/workers/survey_update_worker')
require Rails.root.join('app/workers/ticket_notifications_worker')

describe 'workers scheduled via sidekiq-cron' do
  it 'run daily updates' do
    expect(DailyUpdate).to receive(:new)
    DailyUpdateWorker.perform_async
  end

  it 'run survey updates' do
    expect(SurveyUpdate).to receive(:new)
    SurveyUpdateWorker.perform_async
  end

  it 'run ticket notifications' do
    expect(TicketNotificationEmails).to receive(:notify)
    TicketNotificationsWorker.perform_async
  end
end
