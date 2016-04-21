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
  let(:survey_notification) do
    create(:survey_notification,
           survey_assignment_id: survey_assignment.id,
           courses_users_id: courses_user.id,
           email_sent: email_sent)
  end

  let(:subject) { survey_notification }

  describe 'send_email' do
    context 'when email has not been sent' do
      let(:email_sent) { false }
      it 'sends the email' do
        expect(SurveyMailer).to receive(:notification).and_return(mock_mailer)
        subject.send_email
        expect(subject.email_sent).to eq(true)
      end
    end

    context 'when the user has no email address' do
      let(:email_sent) { false }
      let(:email) { nil }
      it 'returns without error' do
        expect(SurveyMailer).not_to receive(:notification)
        subject.send_email
        expect(subject.email_sent).to eq(false)
      end
    end

    context 'when the email has already been sent' do
      let(:email_sent) { true }
      it 'does not send another email' do
        expect(SurveyMailer).not_to receive(:notification)
        subject.send_email
        expect(subject.email_sent).to eq(true)
      end
    end
  end
end
