# frozen_string_literal: true

require 'rails_helper'

describe DashboardController, type: :request do
  describe '#index' do
    let(:course) { create(:course, end: 2.days.ago) }
    let(:admin) { create(:admin) }

    context 'when the user is not logged it' do
      it 'redirects to landing page' do
        get '/course_creator'
        expect(response.status).to eq(302)
      end
    end

    context 'when user is an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        create(:courses_user, user_id: admin.id, course_id: course.id)
      end

      it 'sets past courses to include just-ended ones' do
        get '/course_creator'
        expect(assigns(:pres).past.count).to eq(1)
      end
    end

    context 'when the blog is down' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        Rails.cache.clear
      end

      it 'sets @blog_posts to empty array' do
        stub_const('DashboardController::BLOG_FEED_URL', 'https://wikiedu.org/not_a_feed')
        VCR.use_cassette 'wikiedu.org/feed' do
          get '/course_creator'
        end
        expect(assigns(:blog_posts)).to eq([])
      end
    end
  end
end
