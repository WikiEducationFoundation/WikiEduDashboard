# frozen_string_literal: true

require 'rails_helper'

describe Courses::DeleteFromCampaignController, type: :request do
  let(:slug) { 'Wikipedia_Fellows/Basket-weaving_fellows_(summer_2018)' }
  let(:flags) { {} }
  let!(:course) { create(:course, slug:, flags:) }
  let!(:campaign) { create(:campaign, title: 'Spring 2016') }
  let!(:campaigns_course) { create(:campaigns_course, course:, campaign:) }
  let(:user) { create(:admin) }
  let(:query) do
    { campaign_title: campaign.title, campaign_id: campaign.id, campaign_slug: campaign.slug }
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
  end

  describe '#delete_course_from_campaign' do
    context 'when the course is only in this campaign' do
      it 'removes the course from the campaign and schedules deletion' do
        expect(DeleteCourseWorker).to receive(:schedule_deletion).once
        delete "/courses/#{course.slug}.json/delete_from_campaign", params: query
        expect(response).to redirect_to(programs_campaign_path(campaign.slug))
        expect(CampaignsCourses.exists?(campaigns_course.id)).to be(false)
      end
    end

    context 'when the course is also in another campaign' do
      let!(:other_campaign) { create(:campaign_two) }
      let!(:other_campaigns_course) { create(:campaigns_course, course:, campaign: other_campaign) }

      it 'removes the course from this campaign only and does not delete it' do
        expect(DeleteCourseWorker).not_to receive(:schedule_deletion)
        delete "/courses/#{course.slug}.json/delete_from_campaign", params: query
        expect(response).to redirect_to(programs_campaign_path(campaign.slug))
        expect(CampaignsCourses.exists?(campaigns_course.id)).to be(false)
        expect(CampaignsCourses.exists?(other_campaigns_course.id)).to be(true)
      end
    end

    context 'when the course is linked to a Wikimedia Event Registration event' do
      let(:flags) { { event_sync: 4296 } }

      it 'refuses to delete the course and leaves it in the campaign' do
        expect(DeleteCourseWorker).not_to receive(:schedule_deletion)
        delete "/courses/#{course.slug}.json/delete_from_campaign", params: query
        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body['message']).to eq(I18n.t('courses.error.event_sync_delete'))
        expect(CampaignsCourses.exists?(campaigns_course.id)).to be(true)
        expect(Course.exists?(course.id)).to be(true)
      end

      context 'when the course is also in another campaign' do
        let!(:other_campaigns_course) do
          create(:campaigns_course, course:, campaign: create(:campaign_two))
        end

        it 'still allows removing it from one campaign, since that does not delete it' do
          expect(DeleteCourseWorker).not_to receive(:schedule_deletion)
          delete "/courses/#{course.slug}.json/delete_from_campaign", params: query
          expect(response).to redirect_to(programs_campaign_path(campaign.slug))
          expect(CampaignsCourses.exists?(campaigns_course.id)).to be(false)
        end
      end
    end

    context 'when the user cannot edit the course' do
      let(:user) { create(:user) }

      it 'does not remove or delete anything' do
        expect(DeleteCourseWorker).not_to receive(:schedule_deletion)
        delete "/courses/#{course.slug}.json/delete_from_campaign", params: query
        expect(response).to have_http_status(:unauthorized)
        expect(CampaignsCourses.exists?(campaigns_course.id)).to be(true)
      end
    end
  end
end
