# frozen_string_literal: true

require 'json'
require 'rails_helper'
require 'factory_bot_rails'

describe AlertsListController, type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:course) { create(:course) }

  describe '#index' do
    let!(:alert) { create(:alert) }

    context 'for admins' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'returns the alerts list' do
        get '/alerts_list.json'

        expect(response.status).to eq(200)
        expect(response.body).to include(alert.type)
      end

      it 'returns resolvable status for resolvable alerts' do
        get '/alerts_list.json'

        expect(response.status).to eq(200)
        expect(response.body).to include('resolvable')
      end

      context 'filtering' do
        let!(:new_user) { create(:user, username: 'username', id: 10001) }
        let!(:onboarding_alert) { create(:onboarding_alert, user: new_user) }

        it 'filters the alerts by user id' do
          get "/alerts_list.json?user_id=#{new_user.id}"

          expect(response.status).to eq(200)
          expect(response.body).to include(onboarding_alert.type)
          expect(response.body).not_to include(alert.type)
        end

        it 'shows onboarding alerts for instructors of a course' do
          create(:courses_user, course:, user: new_user,
                                role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
          get "/alerts_list.json?course_id=#{course.id}"

          expect(response.status).to eq(200)
          expect(response.body).to include(onboarding_alert.type)
          expect(response.body).not_to include(alert.type)
        end

        it 'filters the alerts by type' do
          get "/alerts_list.json?type=#{onboarding_alert.type}"

          expect(response.status).to eq(200)
          expect(response.body).to include(onboarding_alert.type)
          expect(response.body).not_to include(alert.type)
        end

        it 'filters by multiple properties' do
          FactoryBot.build(:onboarding_alert, user_id: user.id)
          get "/alerts_list.json?user_id=#{new_user.id}&type=#{onboarding_alert.type}"

          expect(response.status).to eq(200)
          expect(response.body).to include(new_user.username)
          expect(response.body).to include(onboarding_alert.type)
          expect(response.body).not_to include(user.username)
          expect(response.body).not_to include(alert.type)
        end

        it 'can return information as json' do
          get "/alerts_list?user_id=#{new_user.id}", as: :json

          expect(response.status).to eq(200)
          expect(response.headers['Content-Type']).to include('application/json')

          json = JSON.parse(response.body)
          expect(json['alerts'].length).to eq(1)
          expect(json['alerts'][0]['user_id']).to eq(new_user.id)
        end
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
