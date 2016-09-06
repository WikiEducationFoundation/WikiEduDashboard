# frozen_string_literal: true
require 'rails_helper'

describe SurveyAssignmentsController do
  describe '#create' do
    let(:follow_up)   { 7 }
    let(:send_days)   { 7 }
    let(:send_email)  { true }
    let(:survey)      { create(:survey) }
    let(:cohort)      { create(:cohort) }
    let(:instructor)  { 1 }
    let(:admin)       { create(:admin) }
    let(:post_params) do
      {
        survey_assignment: {
          survey_id: survey.id,
          cohort_ids: cohort.id,
          courses_user_role: instructor,
          send_date_days: send_days,
          send_before: false,
          send_date_relative_to: 'end',
          follow_up_days_after_first_notification: follow_up,
          published: true,
          notes: 'foo',
          send_email: send_email
        }
      }
    end
    before { allow(controller).to receive(:current_user).and_return(admin) }
    it 'allows create and sets appropriate params' do
      post :create, post_params
      expect(SurveyAssignment.last.follow_up_days_after_first_notification).to eq(follow_up)
      expect(SurveyAssignment.last.send_email).to eq(send_email)
    end
  end

  describe '#send_notifications' do
    let(:send_email) { nil }
    let(:admin) { create(:admin) }
    let(:user) { create(:user, email: 'foo@bar.com') }
    let(:courses_user) { create(:courses_user, user_id: user.id) }
    let(:survey) { create(:survey) }
    let(:survey_assignment) do
      create(:survey_assignment, send_email: send_email, survey_id: survey.id)
    end
    let!(:survey_notification) do
      create(:survey_notification, survey_assignment_id: survey_assignment.id,
                                   dismissed: false, completed: false,
                                   courses_users_id: courses_user.id)
    end
    before { allow(controller).to receive(:current_user).and_return(admin) }

    context 'send_email is not set' do
      it 'does not attempt to send' do
        expect(SurveyMailer).not_to receive(:send_notification)
        post :send_notifications
      end
    end

    context 'send_email is set' do
      let(:send_email) { true }
      it 'attempts to send email' do
        expect(SurveyMailer).to receive(:send_notification)
        post :send_notifications
      end
    end
  end

  describe '#send_test_email' do
    let(:admin) { create(:admin) }
    let(:survey) { create(:survey) }
    let(:survey_assignment) do
      create(:survey_assignment, survey_id: survey.id)
    end
    let(:params) { { id: survey_assignment.id } }
    before { allow(controller).to receive(:current_user).and_return(admin) }
    it 'invokes SurveyTestEmailManager and redirects' do
      expect_any_instance_of(SurveyTestEmailManager).to receive(:send_email)
      post :send_test_email, params
      expect(response.status).to eq(302)
    end
  end
end
