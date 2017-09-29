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

      it 'creates a campaign user for the current user' do
        post :create, params: campaign_params
        expect(CampaignsUsers.last.user_id).to eq(admin.id)
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

    context 'when user is not an admin and feature flag is off' do
      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(Features).to receive(:open_course_creation?).and_return(false)
      end

      it 'returns a 401 and does not create a campaign' do
        post :create, params: campaign_params
        expect(response.status).to eq(401)
        expect(Campaign.count).to eq(1)
      end
    end
  end

  describe '#update' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:campaign) { create(:campaign) }
    let(:description) { 'My new campaign is the best campaign ever!' }
    let(:campaign_params) { { slug: campaign.slug, description: description } }

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow(controller).to receive(:current_user).and_return(user)
      delete :update, params: { campaign: campaign_params, slug: campaign.slug }
      expect(response.status).to eq(401)
    end

    it 'updates the campaign if the user is an organizer of the campaign' do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow(controller).to receive(:current_user).and_return(user)
      post :update, params: { campaign: campaign_params, slug: campaign.slug }
      expect(response.status).to eq(302) # redirect to /overview
      expect(campaign.reload.description).to eq(description)
    end

    it 'updates the campaign if the user is an admin' do
      allow(controller).to receive(:current_user).and_return(admin)
      post :update, params: { campaign: campaign_params, slug: campaign.slug }
      expect(response.status).to eq(302) # redirect to /overview
      expect(campaign.reload.description).to eq(description)
    end
  end

  describe '#destroy' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:campaign) { create(:campaign) }

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow(controller).to receive(:current_user).and_return(user)
      delete :destroy, params: { slug: campaign.slug }
      expect(response.status).to eq(401)
      expect(Campaign.find_by_slug(campaign.slug)).not_to be_nil
    end

    it 'deletes the campaign if the user is a campaign organizer' do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow(controller).to receive(:current_user).and_return(user)
      delete :destroy, params: { slug: campaign.slug }
      expect(response.status).to eq(302) # redirect to /campaigns
      expect(Campaign.find_by_slug(campaign.slug)).to be_nil
    end
  end

  describe '#add_organizer' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:campaign) { create(:campaign) }

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow(controller).to receive(:current_user).and_return(user)
      put :add_organizer, params: { slug: campaign.slug, username: 'MusikAnimal' }
      expect(response.status).to eq(401)
      expect(Campaign.find_by_slug(campaign.slug)).not_to be_nil
    end

    it 'adds the given user as an organizer of the campaign if the current user is a campaign organizer' do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      user2 = create(:user, username: 'MusikAnimal')
      allow(controller).to receive(:current_user).and_return(user)
      put :add_organizer, params: { slug: campaign.slug, username: user2.username }
      expect(response.status).to eq(302) # redirect to /overview
      expect(CampaignsUsers.last.user_id).to eq(user2.id)
    end
  end

  describe '#remove_organizer' do
    let(:user) { create(:user) }
    let(:user2) { create(:user, username: 'user2') }
    let(:campaign) { create(:campaign) }
    let(:organizer) do
      create(:campaigns_user, id: 5, user_id: user2.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
    end

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow(controller).to receive(:current_user).and_return(user)
      put :remove_organizer, params: { slug: campaign.slug, id: organizer.user_id }
      expect(response.status).to eq(401)
      expect(CampaignsUsers.find_by_id(organizer.id)).not_to be_nil
    end

    it 'removes the given organizer from the campaign if the current user is a campaign organizer' do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow(controller).to receive(:current_user).and_return(user)
      put :remove_organizer, params: { slug: campaign.slug, id: organizer.user_id }
      expect(response.status).to eq(302) # redirect to /overview
      expect(CampaignsUsers.find_by_id(organizer.id)).to be_nil
    end
  end

  describe '#remove_course' do
    let(:user) { create(:user) }
    let(:campaign) { create(:campaign) }
    let(:course) { create(:course) }
    let!(:campaigns_course) do
      create(:campaigns_course, campaign_id: campaign.id,
                                course_id: course.id)
    end

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow(controller).to receive(:current_user).and_return(user)
      put :remove_course, params: { slug: campaign.slug, course_id: course.id }
      expect(response.status).to eq(401)
      expect(CampaignsCourses.find_by_id(campaigns_course.id)).not_to be_nil
    end

    it 'removes the course from the campaign if the current user is a campaign organizer' do
      create(:campaigns_user, id: 5, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow(controller).to receive(:current_user).and_return(user)
      put :remove_course, params: { slug: campaign.slug, course_id: course.id }
      expect(response.status).to eq(302) # redirect to /overview
      expect(CampaignsCourses.find_by_id(campaigns_course.id)).to be_nil
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
      expect(response.body).to have_content(course.title)
      expect(response.body).to have_content(course.school)
    end
  end

  describe '#articles_csv' do
    let(:course) { create(:course) }
    let(:campaign) { create(:campaign) }
    let(:article) { create(:article) }
    let(:request_params) { { slug: campaign.slug, format: :csv } }

    before do
      campaign.courses << course
      create(:articles_course, article: article, course: course)
    end
    it 'returns a csv of course data' do
      get :articles_csv, params: request_params
      expect(response.body).to have_content(course.slug)
      expect(response.body).to have_content(article.title)
    end
  end

  describe '#overview' do
    render_views
    let(:user) { create(:user) }
    let(:campaign) { create(:campaign) }

    before do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
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
    let(:course2) { create(:course, title: 'course2', slug: 'foo/course2') }
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
      expect(response.body).to have_content(course.school)
      expect(response.body).to have_content(course.term)
    end

    it 'shows a remove button for the programs if the user is an organizer or admin' do
      # don't show it if they are not an organizer or admin
      expect(response.body).to_not have_content(I18n.t('assignments.remove'))

      # when they are an organizer...
      user = create(:user)
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow(controller).to receive(:current_user).and_return(user)
      get :programs, params: { slug: campaign.slug }
      expect(response.body).to have_content(I18n.t('assignments.remove'))

      # when they are an admin...
      admin = create(:admin)
      allow(controller).to receive(:current_user).and_return(admin)
      get :programs, params: { slug: campaign.slug }
      expect(response.body).to have_content(I18n.t('assignments.remove'))
    end

    it 'searches title, school, and term of campaign courses' do
      get :programs, params: { slug: campaign.slug, courses_query: course.title }
      expect(response.body).to have_content(course.title)
    end
  end
end
