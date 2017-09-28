# frozen_string_literal: true

require 'rails_helper'

describe ApplicationController do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:course) { create(:course) }

  controller do
    def index
      head 200
    end
  end

  describe '#new_session_path' do
    it 'returns the sign in path' do
      result = controller.send(:new_session_path, nil)
      expect(result).to eq('/sign_in')
    end
  end

  describe 'invalid authenticity tokens' do
    it 'returns an html 401' do
      exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:check_for_unsupported_browser).and_raise(exception)
      get :index
      expect(response.status).to eq(401)
    end
    it 'returns a json 401' do
      exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:check_for_unsupported_browser).and_raise(exception)
      allow(controller).to receive(:json?).and_return(true)
      get :index, as: :json
      expect(response.status).to eq(401)
    end
  end

  describe '#require_permissions' do
    controller do
      def index
        require_permissions
        head 200
      end
    end

    context 'when user lacks permissions' do
      it 'returns an html 401' do
        allow(controller).to receive(:current_user).and_return(user)
        get :index, params: { id: course.slug }
        expect(response.status).to eq(401)
      end

      it 'returns a json 401' do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:json?).and_return(true)
        get :index, params: { id: course.slug }, as: :json
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#require_participating_user' do
    controller do
      def index
        require_participating_user
        head 200
      end
    end

    context 'when user is not enrolled' do
      it 'returns an html 401' do
        allow(controller).to receive(:current_user).and_return(user)
        get :index, params: { id: course.slug }
        expect(response.status).to eq(401)
      end

      it 'returns a json 401' do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:json?).and_return(true)
        get :index, params: { id: course.slug }, as: :json
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#require_admin_permissions' do
    controller do
      def index
        require_admin_permissions
        head 200
      end
    end

    context 'when user is not an admin' do
      it 'returns an html 401' do
        allow(controller).to receive(:current_user).and_return(user)
        get :index
        expect(response.status).to eq(401)
      end

      it 'returns a json 401' do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:json?).and_return(true)
        get :index, as: :json
        expect(response.status).to eq(401)
      end
    end

    context 'when user is an admin' do
      it 'does not return a 401' do
        allow(controller).to receive(:current_user).and_return(admin)
        get :index
        expect(response.status).to eq(200)
      end
    end
  end

  describe '#require_signed_in' do
    controller do
      def index
        require_signed_in
        head 200
      end
    end

    context 'when user is not signed in' do
      it 'returns an html 401' do
        get :index
        expect(response.status).to eq(401)
      end
      it 'returns a json 401' do
        allow(controller).to receive(:json?).and_return(true)
        get :index, as: :json
        expect(response.status).to eq(401)
      end
    end

    context 'when user is signed in' do
      it 'returns a 200' do
        allow(controller).to receive(:current_user).and_return(user)
        get :index
        expect(response.status).to eq(200)
      end
    end
  end

  describe '#set_locale' do
    let(:user) { create(:user, locale: 'zh-hans') }

    def index
      render nothing: true
    end

    it 'sets the locale from user preference' do
      allow(controller).to receive(:current_user).and_return(user)
      get :index
      expect(I18n.locale).to eq(:'zh-hans')
    end

    it 'sets the locale from a param' do
      get :index, params: { locale: 'zh-hant' }
      expect(I18n.locale).to eq(:'zh-hant')
    end

    it 'falls back to a default if locale is not available' do
      get :index, params: { locale: 'not-a-real-locale' }
      expect(I18n.locale).to eq(:en)
    end
  end
end
