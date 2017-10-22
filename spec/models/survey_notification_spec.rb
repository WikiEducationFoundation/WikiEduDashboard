# frozen_string_literal: true

# == Schema Information
#
# Table name: survey_notifications
#
#  id                     :integer          not null, primary key
#  courses_users_id       :integer
#  course_id              :integer
#  survey_assignment_id   :integer
#  dismissed              :boolean          default(FALSE)
#  email_sent_at          :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  completed              :boolean          default(FALSE)
#  last_follow_up_sent_at :datetime
#  follow_up_count        :integer          default(0)
#

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
  let(:survey) { create(:survey, closed: survey_closed?) }
  let(:survey_closed?) { false }
  let(:follow_up_days) { 7 }
  let(:survey_assignment) do
    create(:survey_assignment, follow_up_days_after_first_notification: follow_up_days,
                               survey_id: survey.id, courses_user_role: role,
                               email_template: email_template)
  end
  let(:role) { CoursesUsers::Roles::INSTRUCTOR_ROLE }
  let(:email_template) { 'instructor_survey' }
  let(:email_sent_at) { 1.hour.ago }
  let(:last_follow_up_sent_at) { nil }
  let(:survey_notification) do
    create(:survey_notification,
           survey_assignment_id: survey_assignment.id,
           courses_users_id: courses_user.id,
           course_id: course.id,
           email_sent_at: email_sent_at,
           last_follow_up_sent_at: last_follow_up_sent_at,
           follow_up_count: follow_up_count,
           completed: completed,
           dismissed: dismissed)
  end
  let(:follow_up_count) { 0 }
  let(:completed) { false }
  let(:dismissed) { false }

  let(:subject) { survey_notification }

  it 'gets destroyed when Course is destroyed' do
    expect(survey_notification).to eq(described_class.last)
    course.destroy
    expect(described_class.last).to be_nil
  end

  it 'gets destroyed when CoursesUser is destroyed' do
    expect(survey_notification).to eq(described_class.last)
    courses_user.destroy
    expect(described_class.last).to be_nil
  end

  it 'gets destroyed when SurveyAssignment is destroyed' do
    expect(survey_notification).to eq(described_class.last)
    survey_assignment.destroy
    expect(described_class.last).to be_nil
  end

  describe '.active' do
    let(:subject) { SurveyNotification.active }

    context 'when the survey is not closed' do
      before { survey_notification }
      it 'includes the active survey notification' do
        expect(subject).to include(survey_notification)
      end
    end

    context 'when the notification is dismissed' do
      let(:dismissed) { true }
      before { survey_notification }
      it 'returns no survey notifications' do
        expect(subject.count).to eq(0)
      end
    end

    context 'when the notification is completed' do
      let(:completed) { true }
      before { survey_notification }
      it 'returns no survey notifications' do
        expect(subject.count).to eq(0)
      end
    end

    context 'when the survey is closed' do
      let(:survey_closed?) { true }
      before { survey_notification }
      it 'returns no survey notifications' do
        expect(subject.count).to eq(0)
      end
    end
  end

  describe '#send_email' do
    context 'when email has not been sent' do
      let(:email_sent_at) { nil }
      it 'sends the email' do
        expect(SurveyMailer).to receive(:instructor_survey_notification).and_return(mock_mailer)
        subject.send_email
        expect((1.minute.ago..1.minute.from_now).cover?(subject.email_sent_at)).to eq(true)
      end
    end

    context 'when the user has no email address' do
      let(:email_sent_at) { nil }
      let(:email) { nil }
      it 'returns without error' do
        expect(SurveyMailer).not_to receive(:instructor_survey_notification)
        subject.send_email
        expect(subject.email_sent_at).to be_nil
      end
    end

    context 'when the email has already been sent' do
      it 'does not send another email' do
        expect(SurveyMailer).not_to receive(:instructor_survey_notification)
        subject.send_email
        expect((1.minute.ago..1.minute.from_now).cover?(subject.email_sent_at)).to eq(false)
      end
    end
  end

  describe '#send_follow_up' do
    context 'follow up not sent, but follow ups not set on assignment' do
      let(:follow_up_days) { nil }
      let(:email_sent_at) { 1.month.ago }

      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:instructor_survey_follow_up)
        subject.send_follow_up
        expect(subject.last_follow_up_sent_at).to be_nil
      end
    end

    context 'follow up was just sent' do
      let(:last_follow_up_sent_at) { 1.hour.ago }
      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:instructor_survey_follow_up)
        subject.send_follow_up
        expect((1.minute.ago..1.minute.from_now).cover?(subject.last_follow_up_sent_at))
          .to eq(false)
      end
    end

    context 'follow ups set on assignment, but it is not yet time to send' do
      let(:email_sent_at) { 1.minute.ago }
      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:instructor_survey_follow_up)
        subject.send_follow_up
        expect(subject.last_follow_up_sent_at).to be_nil
      end
    end
    context 'follow ups set on assignment, it is time to send' do
      let(:email_sent_at) { 8.days.ago }
      it 'sends the follow up' do
        expect(SurveyMailer).to receive(:instructor_survey_follow_up).and_return(mock_mailer)
        subject.send_follow_up
        expect((1.minute.ago..1.minute.from_now).cover?(subject.last_follow_up_sent_at)).to eq(true)
      end
    end

    context 'follow ups set on assignment, it is time to send, but user has no email' do
      let(:email) { nil }
      let(:email_sent_at) { nil }
      let(:last_follow_up_sent_at) { nil }
      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:instructor_survey_follow_up)
        subject.send_follow_up
        expect(subject.last_follow_up_sent_at).to be_nil
      end
    end

    context 'it is time to send, user has email, but no preliminary email set' do
      let(:email) { 'pizza@tacos.com' }
      let(:email_sent_at) { nil }
      let(:last_follow_up_sent_at) { nil }
      it 'does not send the follow up' do
        expect(SurveyMailer).not_to receive(:instructor_survey_follow_up)
        subject.send_follow_up
        expect(subject.last_follow_up_sent_at).to be_nil
      end
    end

    context 'follow ups set on assignment' do
      let(:email) { 'pizza@tacos.com' }
      let(:email_sent_at) { 8.days.ago }

      context 'and first follow up was sent just now' do
        let(:follow_up_count) { 1 }
        let(:last_follow_up_sent_at) { 1.day.ago }
        it 'does not send another follow up' do
          expect(SurveyMailer).not_to receive(:instructor_survey_follow_up)
          subject.send_follow_up
          expect(subject.follow_up_count).to eq(1)
          expect((1.minute.ago..1.minute.from_now).cover?(subject.last_follow_up_sent_at))
            .to eq(false)
        end
      end

      context 'and first follow up was sent longer ago' do
        let(:follow_up_count) { 1 }
        let(:last_follow_up_sent_at) { 8.day.ago }
        it 'sends another follow up' do
          expect(SurveyMailer).to receive(:instructor_survey_follow_up).and_return(mock_mailer)
          subject.send_follow_up
          expect(subject.follow_up_count).to eq(2)
          expect((1.minute.ago..1.minute.from_now).cover?(subject.last_follow_up_sent_at))
            .to eq(true)
        end
      end

      context 'and third follow up was sent longer ago' do
        let(:follow_up_count) { 3 }
        let(:last_follow_up_sent_at) { 8.day.ago }
        it 'does not send another follow up' do
          expect(SurveyMailer).not_to receive(:instructor_survey_follow_up)
          subject.send_follow_up
          expect(subject.follow_up_count).to eq(3)
          expect((1.minute.ago..1.minute.from_now).cover?(subject.last_follow_up_sent_at))
            .to eq(false)
        end
      end
    end
  end
end
