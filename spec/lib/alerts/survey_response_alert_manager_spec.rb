# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/survey_response_alert_manager"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe SurveyResponseAlertManager do
  let(:user) { create(:user) }
  let(:equals_question) do
    create(:q_radio, answer_options: "yes\r\nno\r\n", alert_conditions: { equals: 'yes' })
  end
  let!(:present_question) do
    create(:q_long, validation_rules: { presence: '0' }, alert_conditions: { present: true })
  end

  let(:subject) { SurveyResponseAlertManager.new }

  let(:create_answer) do
    answer_group = create(:answer_group, user_id: user.id)
    create(:answer, answer_group_id: answer_group.id, question_id: question.id,
                    answer_text: answer_text)
  end

  before do
    create(:user, username: 'Samantha (Wiki Ed)', email: 'samantha@wikiedu.org')
    create(:setting, key: 'special_users', value: { survey_alerts_recipient: 'Samantha (Wiki Ed)' })
  end

  context 'when an "equals" condition is met in an answer' do
    let(:question) { equals_question }
    let(:answer_text) { 'yes' }
    it 'creates an alert and sends an email' do
      create_answer
      subject.create_alerts
      expect(Alert.count).to eq(1)
      expect(Alert.last.type).to eq('SurveyResponseAlert')
      expect(Alert.last.email_sent_at).not_to be_nil
    end
  end

  context 'when an "equals" condition is not met in an answer' do
    let(:question) { equals_question }
    let(:answer_text) { 'no' }
    it 'does not create an alert' do
      create_answer
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end

  context 'when a "present" condition question has an answer' do
    let(:question) { present_question }
    let(:answer_text) { 'some answer' }
    it 'creates an alert and sends an email' do
      create_answer
      subject.create_alerts
      expect(Alert.count).to eq(1)
      expect(Alert.last.type).to eq('SurveyResponseAlert')
      expect(Alert.last.email_sent_at).not_to be_nil
    end
  end

  context 'when a "present" condition question has an blank answer' do
    let(:question) { present_question }
    let(:answer_text) { '' }
    it 'does not create an alert' do
      create_answer
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end

  context 'when a condition is met but there is already an alert' do
    let(:question) { equals_question }
    let(:answer_text) { 'yes' }
    before do
      create(:alert, type: 'SurveyResponseAlert', user_id: user.id, subject_id: question.id)
    end

    it 'does not create an alert' do
      expect(Alert.count).to eq(1)
      create_answer
      subject.create_alerts
      expect(Alert.count).to eq(1)
    end
  end
end
