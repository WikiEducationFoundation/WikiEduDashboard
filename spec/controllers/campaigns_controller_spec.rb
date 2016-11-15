# frozen_string_literal: true
require 'rails_helper'

describe CampaignsController do
  render_views

  describe '#index' do
    it 'renders a 200' do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe '#create' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:title) { 'My New? Campaign 5!' }
    let(:expected_slug) { 'my_new_campaign_5' }
    let(:campaign_params) { { campaign: { title: title } } }

    context 'when user is an admin' do
      before do
        allow(controller).to receive(:current_user).and_return(admin)
      end

      it 'creates new campaigns' do
        post :create, params: campaign_params
        expect(Campaign.last.slug).to eq(expected_slug)
      end

      it 'does not create duplicate titles' do
        Campaign.create(title: title, slug: 'foo')
        post :create, params: campaign_params
        expect(Campaign.last.slug).to eq('foo')
      end

      it 'does not create duplicate slugs' do
        Campaign.create(title: 'foo', slug: expected_slug)
        post :create, params: campaign_params
        expect(Campaign.last.title).to eq('foo')
      end
    end

    context 'when user is not an admin' do
      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'returns a 401 and does not create a campaign' do
        post :create, params: campaign_params
        expect(response.status).to eq(401)
        expect(Campaign.count).to eq(1)
      end
    end
  end

  describe '#update' do
    let(:campaign) { create(:campaign) }
    let(:description) { 'My new campaign is the best campaign ever!' }
    let(:campaign_params) { { slug: campaign.slug, description: description } }

    it 'updates the campaign' do
      post :update, params: { campaign: campaign_params, slug: campaign.slug }
      expect(response.status).to eq(200)
      expect(campaign.reload.description).to eq(description)
    end
  end

  describe '#students' do
    let(:course) { create(:course) }
    let(:campaign) { create(:campaign) }
    let(:student) { create(:user) }

    before do
      campaign.courses << course
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    context 'without "course" option' do
      let(:request_params) { { slug: campaign.slug, format: :csv } }

      it 'returns a csv of student usernames' do
        get :students, params: request_params
        expect(response.body).to have_content(student.username)
      end
    end

    context 'with "course" option' do
      let(:request_params) { { slug: campaign.slug, course: true, format: :csv } }

      it 'returns a csv of student usernames with course slugs' do
        get :students, params: request_params
        expect(response.body).to have_content(student.username)
        expect(response.body).to have_content(course.slug)
      end
    end
  end

  describe '#instructors' do
    let(:course) { create(:course) }
    let(:campaign) { create(:campaign) }
    let(:instructor) { create(:user) }

    before do
      campaign.courses << course
      create(:courses_user, course_id: course.id, user_id: instructor.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    context 'without "course" option' do
      let(:request_params) { { slug: campaign.slug, format: :csv } }

      it 'returns a csv of instructor usernames' do
        get :instructors, params: request_params
        expect(response.body).to have_content(instructor.username)
      end
    end

    context 'with "course" option' do
      let(:request_params) { { slug: campaign.slug, course: true, format: :csv } }

      it 'returns a csv of instructor usernames with course slugs' do
        get :instructors, params: request_params
        expect(response.body).to have_content(instructor.username)
        expect(response.body).to have_content(course.slug)
      end
    end
  end

  describe '#courses' do
    let(:course) { create(:course, user_count: 1) }
    let(:campaign) { create(:campaign) }
    let(:instructor) { create(:user) }
    let(:request_params) { { slug: campaign.slug, format: :csv } }

    before do
      campaign.courses << course
      create(:courses_user, course_id: course.id, user_id: instructor.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
    it 'returns a csv of course data' do
      get :courses, params: request_params
      expect(response.body).to have_content(course.slug)
    end
  end

  describe '#overview' do
    render_views
    let(:campaign) { create(:campaign) }

    before do
      get :overview, params: { slug: campaign.slug }
    end

    it 'renders 200' do
      expect(response.status).to eq(200)
    end

    it 'shows the right campaign' do
      expect(response.body).to have_content(campaign.title)
    end

    it 'shows properties of the campaign' do
      expect(response.body).to have_content(campaign.description)
    end
  end

  describe '#programs' do
    render_views
    let(:course) { create(:course) }
    let(:course2) { create(:course, title: 'Skydiving basket-weaving') }
    let(:campaign) { create(:campaign) }

    before do
      campaign.courses << course << course2
      get :programs, params: { slug: campaign.slug }
    end

    it 'renders 200' do
      expect(response.status).to eq(200)
    end

    it 'shows the right campaign' do
      expect(response.body).to have_content(campaign.title)
    end

    it 'lists the programs for the given campaign' do
      expect(response.body).to have_content(course.title)
      expect(response.body).to have_content(course2.title)
    end
  end
end
