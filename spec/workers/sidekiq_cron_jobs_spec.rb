# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/app/workers/daily_update_worker"
require "#{Rails.root}/app/workers/survey_update_worker"
require "#{Rails.root}/app/workers/ticket_notifications_worker"
require "#{Rails.root}/app/workers/default_campaign_update_worker.rb"

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

  context 'when WikiEd Feature enabled' do
    before { allow(Features).to receive(:wiki_ed?).and_return(true) }

    it 'run default campaign update' do
      expect(DefaultCampaignUpdate).to receive(:new)
      DefaultCampaignUpdateWorker.perform_async
    end
  end

  context 'when WikiEd Feature disabled' do
    before { allow(Features).to receive(:wiki_ed?).and_return(false) }

    it 'do not run default campaign update' do
      expect(DefaultCampaignUpdate).not_to receive(:new)
      DefaultCampaignUpdateWorker.perform_async
    end
  end
end
