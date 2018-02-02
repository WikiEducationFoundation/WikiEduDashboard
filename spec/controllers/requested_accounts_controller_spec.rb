# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/user_importer"

describe RequestedAccountsController do
  describe '#request_account' do
    let(:course) { create(:course, end: Time.zone.today + 1.week) }
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }

    describe '#request_account' do
      let(:requested_account) { create(:requested_account, course: course,
                                                           username: 'username',
                                                           email: 'email')
                                                         }

      it 'returns an error if the passcode is invalid' do
        post :request_account, params: { passcode: 'passcode', course_slug: course.slug }
        expect(response.status).to eq(302)
      end

      it 'adds new requested accounts to the course' do
        expect(course.requested_accounts.count).to eq(0)
        post :request_account, params: { passcode: course.passcode,
                                         course_slug: course.slug,
                                         username: 'username', email: 'email' }
        expect(course.requested_accounts.count).to eq(1)
      end

      it 'updates an attribute if the request already exist' do
        post :request_account, params: { passcode: course.passcode,
                                         course_slug: course.slug,
                                         username: requested_account.username,
                                         email: 'newemail' }
        expect(course.requested_accounts.count).to eq(1)
        expect(course.requested_accounts.last.email).to eq('newemail')
      end

      it 'returns a 500 if user is not authorized create accounts now' do
        post :request_account, params: { passcode: course.passcode,
                                         course_slug: course.slug,
                                         create_account_now: true }
        expect(response.status).to eq(500)
      end

      it 'renders a success message if account creation is successful' do
        allow(controller).to receive(:current_user).and_return(admin)
        stub_account_creation
        allow(UserImporter).to receive(:new_from_username).and_return(user)
        post :request_account, params: { passcode: course.passcode,
                                         course_slug: course.slug,
                                         username: 'MyUsername',
                                         email: 'myemail@me.net',
                                         create_account_now: true }
        expect(response.status).to eq(200)
        expect(response.body).to have_content('Created account for MyUsername')
      end

      it 'raises an error if account requests are not enabled' do
        allow(Features).to receive(:enable_account_requests?).and_return(false)
        post :request_account, params: { passcode: course.passcode,
                                         course_slug: course.slug,
                                         username: 'username', email: 'email' }
        expect(response.status).to eq(401)
      end
    end

    describe '#create_accounts' do
      before { RequestedAccount.create(course_id: course.id, username: 'username', email: 'email') }

      it 'does not create the accounts if user is not authorized' do
        allow(controller).to receive(:current_user).and_return(user)
        post :create_accounts, params: { course_slug: course.slug }
        expect(response.status).to eq(401)
        expect(course.flags[:register_accounts]).to be(nil)
        expect(RequestedAccount.count).to eq(1)
      end

      it 'creates the accounts if user is authorized' do
        stub_account_creation
        allow(controller).to receive(:current_user).and_return(admin)
        allow(UserImporter).to receive(:new_from_username).and_return(user)
        post :create_accounts, params: { course_slug: course.slug }
        expect(response.status).to eq(200)
        expect(RequestedAccount.count).to eq(0)
      end
    end

    describe '#enable_account_requests' do
      it 'sets the flag :register_accounts to true' do
        allow(controller).to receive(:current_user).and_return(admin)
        get :enable_account_requests, params: { course_slug: course.slug }
        expect(course.reload.flags[:register_accounts]).to eq(true)
      end
    end

    describe '#destroy' do
      let!(:requested_account) { create(:requested_account, course_id: course.id) }

      it 'deletes a request account if user is authorized' do
        allow(controller).to receive(:current_user).and_return(admin)
        delete :destroy, params: { course_slug: course.slug, id: requested_account.id }
        expect(RequestedAccount.exists?(requested_account.id)).to eq(false)
      end

      it 'does not delete a request account if user is not authorized' do
        allow(controller).to receive(:current_user).and_return(user)
        delete :destroy, params: { course_slug: course.slug, id: requested_account.id }
        expect(RequestedAccount.exists?(requested_account.id)).to eq(true)
        expect(response.status).to be(401)
      end
    end
  end
end
