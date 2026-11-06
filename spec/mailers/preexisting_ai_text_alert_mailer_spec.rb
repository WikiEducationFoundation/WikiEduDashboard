# frozen_string_literal: true

require 'rails_helper'

describe PreexistingAiTextAlertMailer do
  let(:course) { create(:course) }
  let(:instructor) { create(:user, email: 'instructor@example.com') }
  let(:student) { create(:user, username: 'Student', email: 'student@example.com') }
  let(:article) { create(:article, title: 'Kingdom_of_Aksum') }
  let(:origin_edits) do
    [{ rev_id: 101, username: 'Flagged editor', timestamp: '2024-07-01T15:43:21Z',
       flagged: true, already_alerted: false,
       pangram_share_link: 'https://www.pangram.com/history/flagged' },
     { rev_id: 102, username: 'Unflagged editor', timestamp: '2023-12-27T08:28:09Z',
       flagged: false, already_alerted: false,
       pangram_share_link: 'https://www.pangram.com/history/unflagged' }]
  end
  let(:alert) do
    create(:preexisting_ai_text_alert,
           course:, user: student, article:, revision_id: 1382181955,
           details: { article_title: 'Kingdom of Aksum', origin_edits: })
  end

  before do
    create(:courses_user, user: instructor, course:,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    allow(Features).to receive(:email?).and_return(true)
  end

  it 'emails the student and instructors, listing only the flagged earlier edits' do
    mail = described_class.email(alert)
    expect(mail.to).to contain_exactly('student@example.com', 'instructor@example.com')
    expect(mail.body.encoded).to include('Flagged editor')
    expect(mail.body.encoded).not_to include('Unflagged editor')
  end

  it 'records when the alert email was sent' do
    alert.send_alert_emails
    expect(alert.reload.email_sent_at).not_to be_nil
  end

  it 'sends nothing for a private course' do
    course.update(private: true)
    expect(described_class).not_to receive(:send_emails)
    alert.send_alert_emails
  end
end
