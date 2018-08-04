# frozen_string_literal: true

require 'rails_helper'

describe UsersController do
  describe '#update_locale' do
    let(:user) { create(:user, locale: 'fr') }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'returns a 422 if locale is invalid' do
      put 'update_locale', params: { locale: 'bad-locale' }
      expect(response.status).to eq(422)
      expect(user.locale).to eq('fr')
    end

    it 'updates user locale and returns a 200 if locale is valid' do
      put 'update_locale', params: { locale: 'es' }
      expect(response.status).to eq(200)
      expect(user.locale).to eq('es')
    end
  end

  describe '#index' do
    render_views

    context 'when user is NOT admin' do
      let(:user) { create(:user) }

      before { allow(controller).to receive(:current_user).and_return(user) }

      it 'should not authorize' do
        get :index
        expect(response.body).to have_content('Only administrators may do that.')
      end
    end

    context 'when user IS admin' do
      let(:admin) { create(:admin, email: 'admin@email.com') }

      before do
        allow(controller).to receive(:current_user).and_return(admin)
      end

      let!(:instructor) do
        create(:user, email: 'instructor@school.edu',
                      real_name: 'Sare Goss', username: 'saregoss',
                      permissions: User::Permissions::INSTRUCTOR)
      end

      it 'should list instructors by default' do
        get :index

        expect(response.body).to have_content instructor.username
        expect(response.body).to have_content instructor.real_name
        expect(response.body).to have_content instructor.email

        expect(response.body).to_not have_content admin.email
      end

      let(:search_user) { create(:user, email: 'findme@example.com', real_name: 'Joe Bloggs') }

      it 'should accept email param and return associated user' do
        get :index, params: { email: search_user.email }
        expect(response.body).to have_content search_user.email
      end

      it 'should accept real name param and return associated user' do
        get :index, params: { real_name: search_user.real_name }
        expect(response.body).to have_content search_user.real_name
      end
    end
  end
end
