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
    let(:request_params) { { course_id: course.slug, usernames: } }

    context 'when user has permission to edit course' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        course.campaigns << Campaign.first
        stub_oauth_edit
        stub_raw_action
      end

      it 'adds only real users to a course' do
        expect(UserImporter).to receive(:new_from_username)
        post "/mass_enrollment/#{course.slug}", params: request_params
        expect(course.users).to include(user)
        expect(course.users).to include(user2)
        expect(course.users.count).to eq(2)
      end
    end

    context 'when the username list is too long' do
      let(:usernames) { (1..160).map { |i| "Username_#{i}" }.join("\n") }

      it 'returns an error message' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        post "/mass_enrollment/#{course.slug}", params: request_params
        expect(response.body).to include('exceeds the maximum number of users')
      end
    end

    context 'when the :no_max_users flag is set' do
      let(:usernames) { (1..160).map { |i| "Username_#{i}" }.join("\n") }
      let(:course) do
        create(:course, start: 1.day.ago, end: 1.day.from_now, slug: slug_params,
                        flags: { no_max_users: true })
      end

      it 'adds all users to the course' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        expect_any_instance_of(AddUsers).to receive(:add_all_at_once).and_return([])
        post "/mass_enrollment/#{course.slug}", params: request_params
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
