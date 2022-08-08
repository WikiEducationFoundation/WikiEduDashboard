# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/user_importer"

describe RequestedAccountsController, type: :request do
  describe '#request_account' do
    let(:slug_params) { 'Wikipedia_Fellows/Basket-weaving_fellows_(summer_2018)' }
    let(:course) { create(:course, end: Time.zone.today + 1.week, slug: slug_params) }
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:username) { 'username' }
    let(:email) { 'valid@example.com' }

    describe '#index' do
      let(:requested_account) do
        create(
          :requested_account,
          course:,
          username:,
          email:
        )
      end

      it 'should raise an error if the user is not signed in' do
        get '/requested_accounts'
        expect(response.status).to eq(401)
        expect(response.body).to include('authorized')
      end

      it 'should raise an error if the user is not an admin' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)

        get '/requested_accounts'
        expect(response.status).to eq(401)
        expect(response.body).to include('authorized')
      end

      it 'should load the page with requested accounts if the user is an admin' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)

        requested_account
        get '/requested_accounts'
        expect(response.status).to eq(200)
        expect(response.body).to include('Requested accounts')
        expect(response.body).to include(email)
      end
    end

    describe '#request_account' do
      let(:requested_account) do
        create(
          :requested_account,
          course:,
          username:,
          email:
        )
      end

      it 'returns an error if the passcode is invalid' do
        put '/requested_accounts', params: { passcode: 'wrongpasscode', course_slug: course.slug }
        expect(response.status).to eq(302)
      end

      it 'returns an error if the email is invalid' do
        put '/requested_accounts', params: { passcode: course.passcode,
                                             course_slug: course.slug,
                                             username:,
                                             email: 'invalidemail' }
        expect(response.status).to eq(422)
        expect(response.body).to include('invalidemail')
      end

      it 'adds new requested accounts to the course' do
        expect(course.requested_accounts.count).to eq(0)
        put '/requested_accounts', params: { passcode: course.passcode,
                                             course_slug: course.slug,
                                             username:, email: }
        expect(course.requested_accounts.count).to eq(1)
      end

      it 'updates an attribute if the request already exist' do
        put '/requested_accounts', params: { passcode: course.passcode,
                                             course_slug: course.slug,
                                             username: requested_account.username,
                                             email: 'newemail@example.com' }
        expect(course.requested_accounts.count).to eq(1)
        expect(course.requested_accounts.last.email).to eq('newemail@example.com')
      end

      it 'returns a 500 if user is not authorized create accounts now' do
        put '/requested_accounts', params: { passcode: course.passcode,
                                             course_slug: course.slug,
                                             username:,
                                             email: 'newemail@example.com',
                                             create_account_now: true }
        expect(response.status).to eq(500)
      end

      it 'renders a success message if account creation is successful' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        stub_account_creation
        allow(UserImporter).to receive(:new_from_username).and_return(user)
        put '/requested_accounts', params: { passcode: course.passcode,
                                             course_slug: course.slug,
                                             username: 'MyUsername',
                                             email: 'myemail@me.net',
                                             create_account_now: true }
        expect(response.status).to eq(200)
        expect(response.body).to include('Created account for MyUsername')
      end
    end

    describe '#create_accounts' do
      let(:route) { "/requested_accounts/#{course.slug}/create" }

      before { RequestedAccount.create(course_id: course.id, username:, email:) }

      it 'does not create the accounts if user is not authorized' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        post route, params: { course_slug: course.slug }
        expect(response.status).to eq(401)
        expect(course.flags[:register_accounts]).to be(nil)
        expect(RequestedAccount.count).to eq(1)
      end

      it 'creates the accounts if user is authorized' do
        stub_account_creation
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        allow(UserImporter).to receive(:new_from_username).and_return(user)
        post route, params: { course_slug: course.slug }
        expect(response.status).to eq(200)
        expect(RequestedAccount.count).to eq(0)
      end
    end

    describe '#create_all_accounts' do
      before do
        RequestedAccount.create(course_id: course.id, username:, email:)
      end

      it 'does not create the accounts if user is not authorized' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        post '/requested_accounts'
        expect(response.status).to eq(401)
        expect(course.flags[:register_accounts]).to be(nil)
        expect(RequestedAccount.count).to eq(1)
      end

      it 'creates the accounts if user is authorized' do
        stub_account_creation
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        allow(UserImporter).to receive(:new_from_username).and_return(user)
        post '/requested_accounts'
        expect(response.status).to eq(200)
        expect(RequestedAccount.count).to eq(0)
      end
    end

    describe '#enable_account_requests' do
      let(:route) { "/requested_accounts/#{course.slug}/enable_account_requests" }

      it 'sets the flag :register_accounts to true' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        get route, params: { course_slug: course.slug }
        expect(course.reload.flags[:register_accounts]).to eq(true)
      end
    end

    describe '#destroy' do
      let(:route) { "/requested_accounts/#{course.slug}/#{requested_account.id}/delete" }
      let!(:requested_account) do
        create(:requested_account, course_id: course.id, username:, email:)
      end

      it 'deletes a request account if user is authorized' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        delete route, params: { course_slug: course.slug, id: requested_account.id }
        expect(RequestedAccount.exists?(requested_account.id)).to eq(false)
      end

      it 'does not delete a request account if user is not authorized' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        delete route, params: { course_slug: course.slug, id: requested_account.id }
        expect(RequestedAccount.exists?(requested_account.id)).to eq(true)
        expect(response.status).to be(401)
      end
    end
  end
end
