# frozen_string_literal: true
require 'rails_helper'

describe SurveysController do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:survey) { create(:survey, confidential_results: confidential_results) }
  let(:confidential_results) { false }

  describe '#course_select' do
    let!(:course) { create(:course) }
    before { allow(controller).to receive(:current_user).and_return(admin) }

    it 'sets the available courses' do
      get :course_select, id: survey.id
      expect(assigns(:courses).first).to eq(course)
    end
  end

  describe '#index' do
    context 'when the user is not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }
      it 'renders the login template' do
        get :show, id: survey.id
        expect(response.body).to render_template('login')
      end
    end
  end

  describe '#results' do
    before { allow(controller).to receive(:current_user).and_return(admin) }

    context 'when the survey is not confidential' do
      it 'renders the results template' do
        get :results, id: survey.id
        expect(response.body).to render_template('results')
        expect(response.status).to eq(200)
      end
    end

    context 'when the survey is confidential' do
      let(:confidential_results) { true }
      it 'renders a 403' do
        get :results, id: survey.id
        expect(response.status).to eq(403)
      end
    end
  end
end
