# frozen_string_literal: true

require 'rails_helper'

describe MassEnrollmentController, type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, username: 'FirstUser') }
  let(:user2) { create(:user, username: 'SecondUser') }
  let(:slug_params) { 'Wikipedia_Fellows/Basket-weaving_fellows_(summer_2018)' }
  let(:course) { create(:course, start: 1.day.ago, end: 1.day.from_now, slug: slug_params) }
  let(:usernames) do
    "#{user.username}\r\n#{user2.username}\r\nNotARealUserOnWikipedia"
  end

  describe '#index' do
    it 'loads for admins' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      get "/mass_enrollment/#{course.slug}", params: { course_id: course.slug }
      expect(response.status).to eq(200)
    end

    it 'returns a 401 if user lacks permission to edit' do
      get "/mass_enrollment/#{course.slug}", params: { course_id: course.slug }
      expect(response.status).to eq(401)
    end
  end

  describe '#add_users' do
    let(:request_params) { { course_id: course.slug, usernames: usernames } }

    context 'when user has permission to edit course' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        course.campaigns << Campaign.first
        stub_add_user_to_channel_success
        stub_oauth_edit
      end

      it 'adds only real users to a course' do
        expect(UserImporter).to receive(:new_from_username)
        post "/mass_enrollment/#{course.slug}", params: request_params
        expect(course.users).to include(user)
        expect(course.users).to include(user2)
        expect(course.users.count).to eq(2)
      end
    end

    context 'when user cannot edit course' do
      before do
        course.campaigns << Campaign.first
      end

      it 'returns a 401' do
        post "/mass_enrollment/#{course.slug}", params: request_params
        expect(response.status).to eq(401)
      end
    end
  end
end
