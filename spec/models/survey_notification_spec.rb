require 'rails_helper'
require 'spec_helper'

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe SurveyNotification do
  let(:user) { create(:user, email: email) }
  let(:email) { 'instructor@example.edu' }
  let(:course) { create(:course) }
  let(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
  let(:survey_assignment) { create(:survey_assignment) }
  let(:email_sent_at) { 1.hour.ago }
  let(:follow_up_sent_at) { nil }
  let(:survey_notification) do
    create(:survey_notification,
           survey_assignment_id: survey_assignment.id,
           courses_users_id: courses_user.id,
           email_sent_at: email_sent_at,
           follow_up_sent_at: follow_up_sent_at)
  end

  let(:subject) { survey_notification }

  describe 'send_email' do
    context 'when email has not been sent' do
      let(:email_sent_at) { nil }
      it 'sends the email' do
        expect(SurveyMailer).to receive(:notification).and_return(mock_mailer)
        subject.send_email
        expect((1.minute.ago..1.minute.from_now).cover?(subject.email_sent_at)).to eq(true)
      end
    end

    context 'when the user has no email address' do
      let(:email_sent_at) { nil }
      let(:email) { nil }
      it 'returns without error' do
        expect(SurveyMailer).not_to receive(:notification)
        subject.send_email
        expect(subject.email_sent_at).to be_nil
      end
    end

    context 'when the email has already been sent' do
      it 'does not send another email' do
        expect(SurveyMailer).not_to receive(:notification)
        subject.send_email
        expect((1.minute.ago..1.minute.from_now).cover?(subject.email_sent_at)).to eq(false)
      end
    end
  end

  describe '#send_follow_up' do
    context 'follow up not sent, but follow ups not set on assignment' do
      let(:survey_assignment) { create(:survey_assignment, follow_up_days_after_first_notification: nil) }
      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:follow_up)
        subject.send_follow_up
        expect(subject.follow_up_sent_at).to be_nil
      end
    end
    context 'follow up already sent' do
      let(:survey_assignment) { create(:survey_assignment, follow_up_days_after_first_notification: 7) }
      let(:follow_up_sent_at) { 1.hour.ago }
      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:follow_up)
        subject.send_follow_up
        expect((1.minute.ago..1.minute.from_now).cover?(subject.follow_up_sent_at)).to eq(false)
      end
    end
    context 'follow ups set on assignment, but it is not yet time to send' do
      let(:email_sent_at)     { 1.minute.ago }
      let(:survey_assignment) { create(:survey_assignment, follow_up_days_after_first_notification: 7) }
      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:follow_up)
        subject.send_follow_up
        expect((1.minute.ago..1.minute.from_now).cover?(subject.follow_up_sent_at)).to eq(false)
      end
    end
    context 'follow ups set on assignment, it is time to send' do
      let(:email_sent_at)     { 8.days.ago }
      let(:survey_assignment) { create(:survey_assignment, follow_up_days_after_first_notification: 7) }
      it 'sends the follow up' do
        expect(SurveyMailer).to receive(:follow_up).and_return(mock_mailer)
        subject.send_follow_up
        expect((1.minute.ago..1.minute.from_now).cover?(subject.follow_up_sent_at)).to eq(true)
      end
    end
    context 'follow ups set on assignment, it is time to send, but user has no email' do
      let(:email) { nil }
      let(:email_sent_at)     { nil }
      let(:follow_up_sent_at) { nil }
      let(:survey_assignment) { create(:survey_assignment, follow_up_days_after_first_notification: 7) }
      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:follow_up)
        subject.send_follow_up
        expect((1.minute.ago..1.minute.from_now).cover?(subject.follow_up_sent_at)).to eq(false)
      end
    end
    context 'follow ups set on assignment, it is time to send, user has email, but no preliminary email set' do
      let(:email) { 'pizza@tacos.com' }
      let(:email_sent_at)     { nil }
      let(:follow_up_sent_at) { nil }
      let(:survey_assignment) { create(:survey_assignment, follow_up_days_after_first_notification: 7) }
      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:follow_up)
        subject.send_follow_up
        expect(subject.follow_up_sent_at).to be_nil
      end
    end
  end
end
