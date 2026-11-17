# frozen_string_literal: true

require 'rails_helper'

describe QuestionsController, type: :request do
  let(:admin) { create(:admin) }
  let(:super_admin) { create(:super_admin) }
  let(:user) { create(:user) }
  let(:question) { create(:q_checkbox, position: 1) }

  describe '#question' do
    let(:path) { "/surveys/question_group_question/#{question.id}" }

    it 'renders the question in json for an admin' do
      login_as admin
      get path, params: { format: :json }
      expect(Oj.load(response.body)['question']['id']).to eq(question.id)
    end

    it 'refuses a logged-out visitor' do
      get path, params: { format: :json }
      expect(response.status).to eq(401)
    end

    it 'refuses a non-admin user' do
      login_as user
      get path, params: { format: :json }
      expect(response.status).to eq(401)
    end
  end

  describe '#update_position' do
    let(:params) { { id: question.id, position: 50 } }

    it 'updates the position for an admin' do
      login_as admin
      put('/surveys/question_position', params:)
      expect(question.reload.position).to eq(50)
    end

    it 'does not update the position for a logged-out visitor' do
      put('/surveys/question_position', params:)
      expect(question.reload.position).to eq(1)
    end

    it 'does not update the position for a non-admin user' do
      login_as user
      put('/surveys/question_position', params:)
      expect(question.reload.position).to eq(1)
    end
  end

  describe '#results' do
    let(:question) { create(:q_long) }
    let(:respondent) { create(:user, username: 'Respondent', email: 'respondent@example.com') }
    let(:path) { "/survey/question/results/#{question.id}.csv" }

    before do
      create(:answer, question:, answer_group: create(:answer_group, user: respondent))
    end

    it 'sends the answers as CSV to an admin' do
      login_as admin
      get path
      expect(response.body).to include('respondent@example.com')
    end

    it 'refuses a logged-out visitor' do
      get path
      expect(response.status).to eq(401)
      expect(response.body).not_to include('respondent@example.com')
    end

    it 'refuses a non-admin user' do
      login_as user
      get path
      expect(response.status).to eq(401)
      expect(response.body).not_to include('respondent@example.com')
    end

    context 'when the question is part of a confidential survey' do
      before do
        survey = create(:survey, confidential_results: true)
        SurveysQuestionGroup.create(survey:,
                                    rapidfire_question_group_id: question.question_group_id)
      end

      it 'refuses a regular admin' do
        login_as admin
        get path
        expect(response.status).to eq(403)
        expect(response.body).not_to include('respondent@example.com')
      end

      it 'sends the answers as CSV to a super admin' do
        login_as super_admin
        get path
        expect(response.body).to include('respondent@example.com')
      end
    end
  end
end
