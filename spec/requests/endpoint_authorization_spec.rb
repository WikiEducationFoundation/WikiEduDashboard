# frozen_string_literal: true

require 'rails_helper'

# Authorization checks for endpoints that had none, or the wrong one. Each
# section covers a refusal and the use the UI makes of the endpoint.
describe 'Endpoint authorization', type: :request do
  let(:user) { create(:user, username: 'SignedInUser') }
  let(:admin) { create(:admin) }

  describe 'deleting a profile image' do
    let(:owner) { create(:user, username: 'ImageOwner') }

    before { create(:user_profile, user_id: owner.id, image_file_link: 'https://example.org/me.png') }

    it 'is refused to another user' do
      login_as user
      delete "/users/#{owner.username}/profile_image"
      expect(owner.user_profile.reload.image_file_link).to be_present
    end

    it 'works for the profile owner' do
      login_as owner
      delete "/users/#{owner.username}/profile_image"
      expect(owner.user_profile.reload.image_file_link).to be_nil
    end
  end

  describe 'disabling a campaign\'s account requests' do
    let(:campaign) { create(:campaign, slug: 'requests_campaign', register_accounts: true) }
    let(:path) { "/requested_accounts_campaigns/#{campaign.slug}/disable_account_requests" }

    it 'is refused to a logged-out visitor' do
      put path
      expect(campaign.reload.register_accounts).to be true
    end

    it 'is refused to a signed-in user who is not an admin' do
      login_as user
      put path
      expect(campaign.reload.register_accounts).to be true
    end

    it 'works for an admin' do
      login_as admin
      put path
      expect(campaign.reload.register_accounts).to be false
    end
  end

  describe 'removing a course from a campaign via the campaign page' do
    let(:course) { create(:course, slug: 'Shared/Shared_course_(term)') }
    let(:own_campaign) { create(:campaign, title: 'Own', slug: 'own_campaign') }
    let(:other_campaign) { create(:campaign, title: 'Other', slug: 'other_campaign') }

    before do
      course.campaigns << own_campaign
      course.campaigns << other_campaign
      create(:campaigns_user, campaign: own_campaign, user:,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      login_as user
    end

    def remove_from(campaign)
      delete "/courses/#{course.slug}.json/delete_from_campaign",
             params: { campaign_id: campaign.id, campaign_title: campaign.title,
                       campaign_slug: campaign.slug }
    end

    it 'is refused for a campaign the user does not organize' do
      remove_from(other_campaign)
      expect(response.status).to eq(401)
      expect(course.reload.campaigns).to include(other_campaign)
    end

    it 'works for the campaign the user organizes' do
      remove_from(own_campaign)
      expect(course.reload.campaigns).not_to include(own_campaign)
    end
  end
end
