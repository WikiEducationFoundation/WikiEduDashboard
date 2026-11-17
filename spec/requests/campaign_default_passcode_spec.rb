# frozen_string_literal: true

require 'rails_helper'

describe 'Campaign default passcode', type: :request do
  let(:user) { create(:user, username: 'SignedInUser') }
  let(:admin) { create(:admin) }

  describe 'a campaign\'s default passcode' do
    let(:campaign) { create(:campaign, slug: 'passcode_campaign', default_passcode: 'SECRETPASS') }
    let(:organizer) { create(:user, username: 'Organizer') }

    before do
      create(:campaigns_user, campaign:, user: organizer,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
    end

    it 'is left out of the campaign JSON for a logged-out visitor' do
      get "/campaigns/#{campaign.slug}.json"
      expect(response.body).not_to include('SECRETPASS')
    end

    it 'is left off the overview page for a logged-out visitor' do
      get "/campaigns/#{campaign.slug}/overview"
      expect(response.body).not_to include('SECRETPASS')
    end

    it 'is in the campaign JSON for an organizer' do
      login_as organizer
      get "/campaigns/#{campaign.slug}.json"
      expect(response.body).to include('SECRETPASS')
    end

    it 'is still given to a course created in the campaign' do
      allow(Features).to receive(:open_course_creation?).and_return(true)
      allow_any_instance_of(WikiCourseEdits).to receive(:update_course)
      login_as user
      post '/courses', params: { course: { school: 'School', title: 'Course', term: 'Term',
                                           start: '2026-01-05', end: '2026-05-20',
                                           initial_campaign_id: campaign.id } }, as: :json
      expect(Course.last.passcode).to eq('SECRETPASS')
    end
  end
end
