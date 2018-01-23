# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/user_importer"

describe RequestedAccountsController, focus: true do
  describe '#request_account' do
    let(:course) { create(:course, end: Time.zone.today + 1.week) }
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }

    describe '#create' do
      it "adds new requested accounts to the course" do
        expect(course.requested_accounts.count).to eq(0)
        post :request_account, params: { passcode: course.passcode, course_slug: course.slug, username: 'username', email: 'email' }
        expect(course.requested_accounts.count).to eq(1)
      end

      it "does not create the accounts if user is not authorized" do
        allow(controller).to receive(:current_user).and_return(user)
        RequestedAccount.create(course_id: course.id, username: 'username', email: 'email')
        post :create_accounts, params: { course_slug: course.slug }
        expect(response.status).to eq(401)
        expect(course.flags[:register_accounts]).to be(nil)
      end

      it "creates the accounts if user is authorized" do
        stub_account_creation
        allow(controller).to receive(:current_user).and_return(admin)
        allow(UserImporter).to receive(:new_from_username).and_return(user)
        RequestedAccount.create(course_id: course.id, username: 'username', email: 'email')
        post :create_accounts, params: { course_slug: course.slug }
        expect(response.status).to eq(200)
        expect(course.reload.flags[:register_accounts]).to be(true)
      end
    end
  end
end
