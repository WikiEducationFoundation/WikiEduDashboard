# frozen_string_literal: true

require 'rails_helper'

describe ApplicationController do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:super_admin) { create(:super_admin) }
  let(:course) { create(:course) }

  controller do
    def index
      head :ok
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
        head :ok
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
        head :ok
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
        head :ok
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

    context 'when user is a super_admin' do
      it 'does not return a 401' do
        allow(controller).to receive(:current_user).and_return(super_admin)
        get :index
        expect(response.status).to eq(200)
      end
    end
  end

  describe '#require_super_admin_permissions' do
    controller do
      def index
        require_super_admin_permissions
        head :ok
      end
    end

    context 'when user is < admin' do
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

      it 'returns custom error message' do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:json?).and_return(true)
        get :index, as: :json
        message = JSON.parse(response.body)['message']
        expect(message).to eq('Only super administrators may do that.')
      end
    end

    context 'when user is an admin' do
      it 'returns an html 401' do
        allow(controller).to receive(:current_user).and_return(admin)
        get :index
        expect(response.status).to eq(401)
      end

      it 'returns a json 401' do
        allow(controller).to receive(:current_user).and_return(admin)
        allow(controller).to receive(:json?).and_return(true)
        get :index, as: :json
        expect(response.status).to eq(401)
      end
    end

    context 'when user is a super_admin' do
      it 'does not return a 401' do
        allow(controller).to receive(:current_user).and_return(super_admin)
        get :index
        expect(response.status).to eq(200)
      end
    end
  end

  describe '#require_signed_in' do
    controller do
      def index
        require_signed_in
        head :ok
      end
    end

    context 'when user is not signed in' do
      it 'returns an html 401 and stores the return path' do
        get :index
        expect(response.status).to eq(401)
        expect(session[:return_to]).to eq('/anonymous')
        expect(flash[:alert]).to eq('Please sign in.')
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
    let(:user) { create(:user, locale: 'zh-CN') }

    def index
      render nothing: true
    end

    it 'sets the locale from user preference' do
      allow(controller).to receive(:current_user).and_return(user)
      get :index
      expect(I18n.locale).to eq(:'zh-CN')
    end

    it 'sets the locale from a param' do
      get :index, params: { locale: 'zh-TW' }
      expect(I18n.locale).to eq(:'zh-TW')
    end

    it 'falls back to a default if locale is not available' do
      get :index, params: { locale: 'not-a-real-locale' }
      expect(I18n.locale).to eq(:en)
    end
  end

  describe '#after_sign_in_path_for' do
    it 'prioritizes session[:return_to]' do
      session[:return_to] = '/protected'
      expect(controller.after_sign_in_path_for(user)).to eq('/protected')
      expect(session[:return_to]).to be_nil
    end

    it 'falls back to omniauth.origin' do
      request.env['omniauth.origin'] = '/origin'
      expect(controller.after_sign_in_path_for(user)).to eq('/origin')
    end

    it 'defaults to root path' do
      expect(controller.after_sign_in_path_for(user)).to eq('/')
    end

    it 'prevents open redirects by extracting only the path from a full URL' do
      session[:return_to] = 'http://evil.com/malicious'
      expect(controller.after_sign_in_path_for(user)).to eq('/malicious')
    end

    it 'falls back to root path if return_to is an invalid or non-relative string' do
      session[:return_to] = 'not-a-valid-path'
      expect(controller.after_sign_in_path_for(user)).to eq('/')
    end

    it 'handles download safety for ungreeted' do
      session[:return_to] = '/ungreeted'
      expect(controller.after_sign_in_path_for(user)).to eq('/')
      expect(flash[:notice]).to include('/ungreeted')
    end

    it 'handles download safety for csv' do
      session[:return_to] = '/data.csv'
      expect(controller.after_sign_in_path_for(user)).to eq('/')
      expect(flash[:notice]).to include('/data.csv')
    end
  end
end
