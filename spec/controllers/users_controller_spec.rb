# frozen_string_literal: true

require 'rails_helper'

describe UsersController, type: :request do
  describe '#index' do
    context 'when user is NOT admin' do
      let(:user) { create(:user) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'does not authorize' do
        get '/users'
        expect(response.body).to include('Only administrators may do that.')
      end
    end

    context 'when user IS admin' do
      let(:admin) { create(:admin, email: 'admin@email.com') }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      let!(:instructor) do
        create(:user, email: 'instructor@school.edu',
                      real_name: 'Sare Goss', username: 'saregoss',
                      permissions: User::Permissions::INSTRUCTOR)
      end

      let(:search_user) { create(:user, email: 'findme@example.com', real_name: 'Joe Bloggs') }

      it 'lists instructors by default' do
        get '/users'
        expect(response.body).to include(instructor.username)
        expect(response.body).to include(instructor.real_name)
        expect(response.body).to include(instructor.email)
        expect(response.body).not_to include(admin.email)
      end

      it 'accepts email param and return associated user' do
        get '/users', params: { email: search_user.email }
        expect(response.body).to include(search_user.email)
      end

      it 'accepts real name param and return associated user' do
        get '/users', params: { real_name: search_user.real_name }
        expect(response.body).to include(search_user.real_name)
      end
    end
  end
end
