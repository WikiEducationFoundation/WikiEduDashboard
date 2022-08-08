# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/user_importer"

describe RequestedAccountsCampaignsController, type: :request do
  describe '#request_account' do
    let(:course) { create(:course, end: Time.zone.today + 1.week) }
    let(:campaign) { create(:campaign, register_accounts: true) }

    let!(:campaigns_courses) do
      create(
        :campaigns_course,
        course_id: course.id,
        campaign_id: campaign.id
      )
    end

    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:requested_account) do
      create(
        :requested_account,
        course:,
        username: 'username',
        email: 'email@example.com'
      )
    end

    describe '#create_accounts' do
      let(:route) { "/requested_accounts_campaigns/#{campaign.slug}/create" }

      before do
        RequestedAccount.create(course_id: course.id, username: 'username',
                                email: 'email@example.com')
      end

      it 'does not create the accounts if user is not authorized' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        get route, params: { campaign_slug: campaign.slug }
        expect(response.status).to eq(401)
        expect(course.flags[:register_accounts]).to be(nil)
        expect(RequestedAccount.count).to eq(1)
      end

      it 'creates the accounts if user is authorized' do
        stub_account_creation
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        allow(UserImporter).to receive(:new_from_username).and_return(user)
        get route, params: { campaign_slug: campaign.slug }
        expect(response.status).to eq(200)
        expect(RequestedAccount.count).to eq(0)
      end
    end

    describe '#disable_account_requests' do
      let(:route) { "/requested_accounts_campaigns/#{campaign.slug}/disable_account_requests" }

      it 'sets the :register_accounts to false' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        put route, params: { campaign_slug: campaign.slug }
        expect(campaign.reload.register_accounts).to eq(false)
      end
    end

    describe '#enable_account_requests' do
      let(:route) { "/requested_accounts_campaigns/#{campaign.slug}/enable_account_requests" }

      it 'sets the :register_accounts to true' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        put route, params: { campaign_slug: campaign.slug }
        expect(campaign.reload.register_accounts).to eq(true)
      end
    end
  end
end
