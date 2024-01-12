# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/automated_emails/term_recap_email_scheduler')

describe TermRecapEmailScheduler do
  let(:student_program_campaign) { create(:campaign, title: 'Spring 2021', slug: 'spring_2021') }
  let(:other_campaign) { create(:campaign, title: 'CC', slug: 'communicating_science') }
  let(:characters) { 1000 }
  let(:users) { 2 }
  let(:course) do
    create(:course, start: 1.week.ago, end: 1.day.ago, character_sum: characters,
                    user_count: users, campaigns: [student_program_campaign, other_campaign])
  end

  context 'when a student program course ended recently' do
    it 'schedules a term recap email' do
      expect(TermRecapEmailWorker).to receive(:perform_async)
        .with(course.id, student_program_campaign.id)
      described_class.schedule_emails
    end
  end

  context 'when a course ended more than 7 days ago' do
    let!(:course) do
      create(:course, start: 1.week.ago, end: 8.days.ago, character_sum: characters,
                      user_count: users, campaigns: [student_program_campaign, other_campaign])
    end

    it 'does not schedule a term recap email' do
      expect(TermRecapEmailWorker).not_to receive(:perform_async)
      described_class.schedule_emails
    end
  end

  context 'when a course is not a student program course' do
    let!(:course) do
      create(:course, start: 1.week.ago, end: 8.days.ago, character_sum: characters,
                      user_count: users, campaigns: [other_campaign])
    end

    it 'does not schedule a term recap email' do
      expect(TermRecapEmailWorker).not_to receive(:perform_async)
      described_class.schedule_emails
    end
  end

  context 'when a course has already been sent a term recap email' do
    let!(:course) do
      create(:course, start: 1.week.ago, end: 8.days.ago, character_sum: characters,
                      user_count: users, campaigns: [student_program_campaign, other_campaign],
                      flags: { recap_sent_at: 1.day.ago })
    end

    it 'does not schedule a term recap email' do
      expect(TermRecapEmailWorker).not_to receive(:perform_async)
      described_class.schedule_emails
    end
  end

  context 'when a course has been withdrawn' do
    let!(:course) do
      create(:course, start: 1.week.ago, end: 1.day.ago, character_sum: characters,
                      user_count: users, campaigns: [student_program_campaign, other_campaign],
                      withdrawn: true)
    end

    it 'does not schedule a term recap email' do
      expect(TermRecapEmailWorker).not_to receive(:perform_async)
      described_class.schedule_emails
    end
  end

  context 'when a course did no work' do
    let!(:course) do
      create(:course, start: 1.week.ago, end: 1.day.ago, character_sum: 0,
                      user_count: users, campaigns: [student_program_campaign, other_campaign])
    end

    it 'does not schedule a term recap email' do
      expect(TermRecapEmailWorker).not_to receive(:perform_async)
      described_class.schedule_emails
    end
  end
end
