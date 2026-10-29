# frozen_string_literal: true

require 'rails_helper'

describe 'Question group results for a confidential survey', type: :request do
  let(:survey) { create(:survey, confidential_results: true) }
  let(:question_group) { create(:question_group, name: 'Confidential group') }
  let(:path) { "/surveys/rapidfire/question_groups/#{question_group.id}/results" }

  before do
    survey.rapidfire_question_groups << question_group
    question = create(:q_long, question_group_id: question_group.id)
    answer_group = Rapidfire::AnswerGroup.create!(question_group:, user: create(:user))
    Rapidfire::Answer.create!(answer_group:, question:, answer_text: 'CONFIDENTIAL-ANSWER')
  end

  it 'are refused to an admin who is not a super admin' do
    login_as create(:admin)
    get path, params: { format: :json }
    expect(response.status).to eq(403)
    expect(response.body).not_to include('CONFIDENTIAL-ANSWER')
  end

  it 'stay visible to a regular admin when the survey is not confidential' do
    survey.update(confidential_results: false)
    login_as create(:admin)
    get path, params: { format: :json }
    expect(response.body).to include('CONFIDENTIAL-ANSWER')
  end

  it 'are shown to a super admin' do
    login_as create(:super_admin)
    get path, params: { format: :json }
    expect(response.body).to include('CONFIDENTIAL-ANSWER')
  end

  # Rapidfire's own admin check raised an unhandled AccessDenied (a 500).
  it 'refuses Rapidfire\'s admin pages to a non-admin with a 403' do
    login_as create(:user, username: 'NotAnAdmin')
    get "/surveys/rapidfire/question_groups/#{question_group.id}/edit"
    expect(response.status).to eq(403)
  end
end
