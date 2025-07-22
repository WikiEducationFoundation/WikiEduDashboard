# frozen_string_literal: true

require 'rails_helper'

describe SurveysController, type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:survey) { create(:survey, confidential_results:, closed:) }
  let(:confidential_results) { false }
  let(:closed) { false }

  describe '#course_select' do
    let!(:course) { create(:course) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    it 'sets the available courses' do
      get "/surveys/select_course/#{survey.id}"
      expect(assigns(:courses).first).to eq(course)
    end
  end

  describe '#index' do
    context 'when the user is not logged in' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it 'renders the login template' do
        get "/surveys/#{survey.id}"
        expect(response.body).to render_template('login')
      end
    end

    context 'when the survey is closed' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      let(:closed) { true }

      it 'redirects to the home page' do
        get "/surveys/#{survey.id}"
        expect(response.body).to redirect_to(root_path)
      end
    end
  end

  describe '#results' do
    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    context 'when the survey is not confidential' do
      it 'renders the results template' do
        get "/survey/results/#{survey.id}"
        expect(response.body).to render_template('results')
        expect(response.status).to eq(200)
      end
    end

    context 'when the survey is confidential' do
      let(:confidential_results) { true }

      it 'renders a 403' do
        get "/survey/results/#{survey.id}"
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#update_question_group_position' do
    before do
      create(:question_group, id: 1)
      create(:question_group, id: 2)
      SurveysQuestionGroup.create(id: 1, survey_id: survey.id, rapidfire_question_group_id: 1)
      SurveysQuestionGroup.create(id: 2, survey_id: survey.id, rapidfire_question_group_id: 2)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    let(:params) { { survey_id: survey.id, question_group_id: 1, position: 2 } }

    it 'orders the question groups' do
      post '/surveys/update_question_group_position', params: params
      expect(SurveysQuestionGroup.find(2).position).to eq(1)
    end
  end
end
