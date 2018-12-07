# frozen_string_literal: true

require 'rails_helper'

describe AlertsListController, type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe '#index' do
    let!(:alert) { create(:alert) }

    context 'for admins' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'renders the alerts list' do
        get '/alerts_list'

        expect(response.status).to eq(200)
        expect(response.body).to include(alert.type)
      end

      it 'renders resolve button for resolvable alerts' do
        get '/alerts_list'

        expect(response.status).to eq(200)
        expect(response.body).to include('Resolve')
      end
    end

    context 'for non-admins' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'redirects to the home page' do
        get '/alerts_list'
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#show' do
    let(:course) { create(:course) }
    let(:user) { create(:user) }
    let(:article) { create(:article) }

    let(:alert) { create(:alert, type: 'NeedHelpAlert', course_id: course.id, user_id: user.id) }
    let(:articles_for_deletion_alert) do
      create(:alert, article_id: article.id,
                     course_id: course.id,
                     type: 'ArticlesForDeletionAlert')
    end

    context 'for admins' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'renders the alert' do
        get "/alerts_list/#{alert.id}"

        expect(response.status).to eq(200)
        expect(response.body).to include(alert.type)
      end

      it 'renders the alert with resolve button' do
        get "/alerts_list/#{articles_for_deletion_alert.id}"

        expect(response.status).to eq(200)
        expect(response.body).to include('Resolve')
      end
    end

    context 'for non-admins' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'redirects to the home page' do
        get "/alerts_list/#{alert.id}"
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
