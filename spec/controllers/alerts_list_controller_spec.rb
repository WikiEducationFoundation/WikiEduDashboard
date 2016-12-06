# frozen_string_literal: true
require 'rails_helper'

describe AlertsListController do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe '#index' do
    let!(:alert) { create(:alert) }
    context 'for admins' do
      render_views
      before { allow(controller).to receive(:current_user).and_return(admin) }
      it 'renders the alerts list' do
        get :index
        expect(response.status).to eq(200)
        expect(response.body).to have_content(alert.type)
      end
    end

    context 'for non-admins' do
      before { allow(controller).to receive(:current_user).and_return(user) }
      it 'redirects to the home page' do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#show' do
    let(:course) { create(:course) }
    let(:user) { create(:user) }
    let!(:alert) { create(:alert, type: 'NeedHelpAlert', course_id: course.id, user_id: user.id) }
    context 'for admins' do
      render_views
      before { allow(controller).to receive(:current_user).and_return(admin) }
      it 'renders the alert' do
        get :show, params: { id: alert.id }
        expect(response.status).to eq(200)
        expect(response.body).to have_content(alert.type)
      end
    end

    context 'for non-admins' do
      before { allow(controller).to receive(:current_user).and_return(user) }
      it 'redirects to the home page' do
        get :show, params: { id: alert.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
