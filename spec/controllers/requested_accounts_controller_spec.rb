# frozen_string_literal: true

require 'rails_helper'

describe RequestedAccountsController do
  describe '#request_account' do
    let(:course) { create(:course, end: Time.zone.today + 1.week) }

    describe '#create' do
      it "adds new requested accounts to the course" do
        expect(course.requested_accounts.count).to eq(0)
        post :request_account, params: { passcode: course.passcode, course_slug: course.slug, username: 'username', email: 'email' }
        expect(course.requested_accounts.count).to eq(1)
      end

      it "does not create the accounts stored as it not authorized" do
        RequestedAccount.create(course_id: course.id, username: 'username', email: 'email')
        post :create_accounts, params: { course_slug: course.slug }
        expect(response.status).to eq(401)
        expect(course.flags[:register_accounts]).to be(nil)
      end
    end
  end
end
