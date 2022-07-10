# frozen_string_literal: true

require 'rails_helper'

describe ExploreController, type: :request do
  let!(:campaign) do
    create(:campaign, title: 'My awesome campaign',
                      start: Date.civil(2016, 1, 10),
                      end: Date.civil(2050, 1, 10))
  end

  let(:admin) { create(:admin) }

  describe '#index' do
    it 'redirects to campaign overview if given a campaign URL param' do
      campaign = create(:campaign)
      get '/explore', params: { campaign: campaign.slug }
      expect(response.status).to eq(302)
      expect(response).to redirect_to(campaign_path(campaign.slug))
    end

    describe 'lists active courses of the default campaign' do
      let(:course) do
        create(:course, title: 'My awesome course',
                        start: Date.civil(2016, 1, 10),
                        end: Date.civil(2050, 1, 10))
      end
      let(:course2) do
        create(:course, title: 'course2',
                        slug: 'foo/course2',
                        start: Date.civil(2016, 1, 10),
                        end: Date.civil(2016, 2, 10))
      end

      before do
        CampaignsCourses.create(course_id: course.id,
                                campaign_id: Campaign.default_campaign.id)
        CampaignsCourses.create(course_id: course2.id,
                                campaign_id: Campaign.default_campaign.id)
      end

      it 'as json' do
        get '/explore', as: :json
        expect(response.body).to include(course.title)
        expect(response.body).not_to include(course2.title)
      end
    end
  end
end
