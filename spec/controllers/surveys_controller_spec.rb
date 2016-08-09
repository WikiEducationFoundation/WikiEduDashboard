# frozen_string_literal: true
require 'rails_helper'

describe SurveysController do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:survey) { create(:survey) }

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
end
