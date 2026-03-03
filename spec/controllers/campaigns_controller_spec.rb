# frozen_string_literal: true

require 'rails_helper'

describe CampaignsController, type: :request do
  describe '#index' do
    it 'renders a 200' do
      get '/campaigns'
      expect(response.status).to eq(200)
    end
  end

  describe '#create' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:title) { 'My New? Campaign 5!' }
    let(:expected_slug) { 'my_new_campaign_5' }
    let(:campaign_params) do
      { campaign: { title:,
                    default_passcode: 'custom',
                    custom_default_passcode: 'ohai' } }
    end

    context 'when user is an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'creates new campaigns with custom passcodes' do
        post '/campaigns', params: campaign_params
        new_campaign = Campaign.last
        expect(new_campaign.slug).to eq(expected_slug)
        expect(new_campaign.default_passcode).to eq('ohai')
      end

      it 'creates a campaign user for the current user' do
        post '/campaigns', params: campaign_params
        expect(CampaignsUsers.last.user_id).to eq(admin.id)
      end

      it 'does not create duplicate titles' do
        Campaign.create(title:, slug: 'foo')
        post '/campaigns', params: campaign_params
        expect(Campaign.last.slug).to eq('foo')
      end

      it 'does not create duplicate slugs' do
        Campaign.create(title: 'foo', slug: expected_slug)
        post '/campaigns', params: campaign_params
        expect(Campaign.last.title).to eq('foo')
      end
    end

    context 'when user is not an admin and feature flag is off' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        allow(Features).to receive(:open_course_creation?).and_return(false)
      end

      it 'returns a 401 and does not create a campaign' do
        post '/campaigns', params: campaign_params
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
    let(:campaign_params) { { slug: campaign.slug, description: } }
    let(:request_params) { { campaign: campaign_params, slug: campaign.slug } }

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      delete "/campaigns/#{campaign.slug}", params: request_params
      expect(response.status).to eq(401)
    end

    it 'updates the campaign if the user is an organizer of the campaign' do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      put "/campaigns/#{campaign.slug}", params: request_params
      expect(response.status).to eq(302) # redirect to /overview
      expect(campaign.reload.description).to eq(description)
    end

    it 'updates the campaign if the user is an admin' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      put "/campaigns/#{campaign.slug}", params: request_params
      expect(response.status).to eq(302) # redirect to /overview
      expect(campaign.reload.description).to eq(description)
    end
  end

  describe '#destroy' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:campaign) { create(:campaign) }
    let(:request_params) { { slug: campaign.slug } }

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      delete "/campaigns/#{campaign.slug}", params: request_params
      expect(response.status).to eq(401)
      expect(Campaign.find_by(slug: campaign.slug)).not_to be_nil
    end

    it 'deletes the campaign if the user is a campaign organizer' do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      delete "/campaigns/#{campaign.slug}", params: request_params
      expect(response.status).to eq(302) # redirect to /campaigns
      expect(Campaign.find_by(slug: campaign.slug)).to be_nil
    end
  end

  describe '#add_organizer' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:campaign) { create(:campaign) }

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      request_params = { slug: campaign.slug, username: 'MusikAnimal' }
      put "/campaigns/#{campaign.slug}/add_organizer", params: request_params
      expect(response.status).to eq(401)
      expect(Campaign.find_by(slug: campaign.slug)).not_to be_nil
    end

    it 'adds the given user as an organizer of the campaign ' \
       'if the current user is a campaign organizer' do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      user2 = create(:user, username: 'MusikAnimal')
      request_params = { slug: campaign.slug, username: user2.username }
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      put "/campaigns/#{campaign.slug}/add_organizer", params: request_params
      expect(response.status).to eq(302) # redirect to /overview
      expect(CampaignsUsers.last.user_id).to eq(user2.id)
    end
  end

  describe '#remove_organizer' do
    let(:user) { create(:user) }
    let(:user2) { create(:user, username: 'user2') }
    let(:campaign) { create(:campaign) }
    let(:request_params) { { slug: campaign.slug, id: organizer.user_id } }
    let(:organizer) do
      create(:campaigns_user, user_id: user2.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
    end

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      put "/campaigns/#{campaign.slug}/remove_organizer", params: request_params
      expect(response.status).to eq(401)
      expect(CampaignsUsers.find_by(id: organizer.id)).not_to be_nil
    end

    it 'removes the given organizer from the campaign ' \
       'if the current user is a campaign organizer' do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      put "/campaigns/#{campaign.slug}/remove_organizer", params: request_params
      expect(response.status).to eq(302) # redirect to /overview
      expect(CampaignsUsers.find_by(id: organizer.id)).to be_nil
    end
  end

  describe '#remove_course' do
    let(:user) { create(:user) }
    let(:campaign) { create(:campaign) }
    let(:course) { create(:course) }
    let(:request_params) { { slug: campaign.slug, course_id: course.id } }
    let!(:campaigns_course) do
      create(:campaigns_course, campaign_id: campaign.id,
                                course_id: course.id)
    end

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      put "/campaigns/#{campaign.slug}/remove_course", params: request_params
      expect(response.status).to eq(401)
      expect(CampaignsCourses.find_by(id: campaigns_course.id)).not_to be_nil
    end

    it 'removes the course from the campaign if the current user is a campaign organizer' do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      put "/campaigns/#{campaign.slug}/remove_course", params: request_params
      expect(response.status).to eq(302) # redirect to /overview
      expect(CampaignsCourses.find_by(id: campaigns_course.id)).to be_nil
    end
  end

  describe '#users.json' do
    let(:course) { create(:course) }
    let(:campaign) { create(:campaign) }
    let(:student) { create(:user) }
    let(:instructor) { create(:user, username: 'Dr. Instructor') }

    before do
      campaign.courses << course
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:courses_user, course_id: course.id, user_id: instructor.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    it 'returns list of students and instructors' do
      get "/campaigns/#{campaign.slug}/users", params: { format: :json }
      expect(response.body).to include(student.username)
      expect(response.body).to include('Editor')
      expect(response.body).to include(instructor.username)
      expect(response.body).to include('Facilitator')
      expect(response.body).to include(course.slug)
      expect(response.body).to include(campaign.slug)
    end
  end

  describe '#assignments.json' do
    let(:course) { create(:course) }
    let(:campaign) { create(:campaign) }
    let(:student) { create(:user) }
    let(:article) { create(:article, title: 'Selfie') }

    before do
      campaign.courses << course
      create(:assignment, course:, user: student, article_title: 'Music',
             role: Assignment::Roles::ASSIGNED_ROLE)
      create(:assignment, course:, user: student, article_title: 'Selfie',
             article:, role: Assignment::Roles::REVIEWING_ROLE)
    end

    it 'returns list of students and instructors' do
      get "/campaigns/#{campaign.slug}/assignments", params: { format: :json }
      expect(response.body).to include(student.username)
      expect(response.body).to include('Editing')
      expect(response.body).to include('Reviewing')
      expect(response.body).to include(course.slug)
      expect(response.body).to include(campaign.slug)
      expect(response.body).to include(article.title)
      expect(response.body).to include('Music')
    end
  end

  describe '#overview' do
    let(:user) { create(:user) }
    let(:campaign) { create(:campaign, description: 'New description') }

    before do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      get "/campaigns/#{campaign.slug}/overview", params: { slug: campaign.slug }
    end

    it 'renders 200' do
      expect(response.status).to eq(200)
    end

    it 'shows the right campaign' do
      expect(response.body).to include(campaign.title)
    end

    it 'shows properties of the campaign' do
      expect(response.body).to include(campaign.description)
    end
  end

  describe '#programs' do
    let(:course) { create(:course) }
    let(:course2) { create(:course, title: 'course2', slug: 'foo/course2') }
    let(:campaign) { create(:campaign) }

    before do
      campaign.courses << course << course2
      get "/campaigns/#{campaign.slug}/programs", params: { slug: campaign.slug }
    end

    it 'renders 200' do
      expect(response.status).to eq(200)
    end

    it 'shows the right campaign' do
      expect(response.body).to include(campaign.title)
    end

    it 'lists the programs for the given campaign' do
      expect(response.body).to include(course.title)
      expect(response.body).to include(course2.title)
      expect(response.body).to include(course.school)
      expect(response.body).to include(course.term)
    end

    it 'shows a remove button for the programs if the user is an organizer or admin' do
      # don't show it if they are not an organizer or admin
      expect(response.body).not_to include(I18n.t('assignments.remove'))

      # when they are an organizer...
      user = create(:user)
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      get "/campaigns/#{campaign.slug}/programs", params: { slug: campaign.slug }
      expect(response.body).to include(I18n.t('assignments.remove'))

      # when they are an admin...
      admin = create(:admin)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      get "/campaigns/#{campaign.slug}/programs", params: { slug: campaign.slug }
      expect(response.body).to include(I18n.t('assignments.remove'))
    end

    it 'searches title, school, and term of campaign courses' do
      request_params = { slug: campaign.slug, courses_query: course.title }
      get "/campaigns/#{campaign.slug}/programs", params: request_params
      expect(response.body).to include(course.title)
    end
  end

  describe '#current_term' do
    it 'redirects to the corresponding subpage for the default term' do
      get '/current_term/articles'
      expect(response).to redirect_to '/campaigns/spring_2015/articles'
    end
  end

  describe 'CampaignsController#articles' do
    let(:campaign) { create(:campaign) }
    let(:course) { create(:course) }
    let(:article) { create(:article) }

    before do
      create(:campaigns_course, campaign:, course:)
      create(:articles_course, course:, article:, tracked: true)
    end

    describe 'GET #articles' do
      context 'when caching is enabled' do
        before do
          # Enable caching to reproduce production behavior
          Rails.application.config.action_controller.perform_caching = true
          ActionController::Base.perform_caching = true
        end

        after do
          # Restore original caching setting
          Rails.application.config.action_controller.perform_caching = false
          ActionController::Base.perform_caching = false
        end

        it 'renders articles page successfully with caching enabled' do
          get "/campaigns/#{campaign.slug}/articles"

          expect(response).to be_successful
          expect(response).to render_template(:articles)
          expect(assigns(:presenter)).to be_present
        end

        it 'does not raise missing attribute error when fragment caching is used' do
          expect do
            get "/campaigns/#{campaign.slug}/articles"
          end.not_to raise_error
        end

        it 'includes required attributes for caching in articles_courses data' do
          get "/campaigns/#{campaign.slug}/articles"

          result = assigns(:presenter).campaign_articles
          articles_courses = result[:articles_courses]

          # Ensure the first article_course has the required attributes for caching
          expect(articles_courses.first).to respond_to(:updated_at)
          expect(articles_courses.first).to respond_to(:id)
          expect(articles_courses.first).to respond_to(:article_id)
          expect(articles_courses.first).to respond_to(:course_id)
        end
      end

      context 'when too_many_articles is true' do
        before do
          allow_any_instance_of(CoursesPresenter).to receive(:too_many_articles?).and_return(true)
        end

        it 'renders too_many_articles template' do
          get "/campaigns/#{campaign.slug}/articles"

          expect(response).to render_template(:too_many_articles)
          expect(assigns(:too_many_message)).to be_present
        end
      end

      context 'when requesting JSON format' do
        it 'returns campaign articles as JSON' do
          get "/campaigns/#{campaign.slug}/articles.json"

          expect(response).to be_successful
          expect(response.content_type).to include('application/json')

          json_response = JSON.parse(response.body)
          expect(json_response['campaign']).to eq(campaign.slug)
          expect(json_response).to have_key('articles')
        end
      end

      context 'with pagination' do
        before do
          # Create more articles to test pagination
          10.times do |i|
            article = create(:article, title: "Test Article #{i}")
            create(:articles_course, course:, article:, tracked: true)
          end
        end

        it 'handles pagination correctly' do
          get "/campaigns/#{campaign.slug}/articles?page=2"

          expect(response).to be_successful
          expect(assigns(:page)).to eq(2)
        end
      end

      context 'when campaign does not exist' do
        it 'raises routing error' do
          get '/campaigns/non-existent-campaign/articles'
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe 'Clear Campaign cache and recalculate stats' do
    let(:campaign) { create(:campaign, slug: 'test-refresh') }

    it 'clears the course sums cache and redirects to overview with notice' do
      original_cache = Rails.cache
      # Use MemoryStore in since default tests uses NullStore which (ignores writes)
      Rails.cache = ActiveSupport::Cache::MemoryStore.new

      begin
        key = campaign.course_sums_cache_key

        Rails.cache.write(key, { courses_count: 42 })
        expect(Rails.cache.read(key)).not_to be_nil, 'Cache write failed'

        # Trigger the refresh (should clear)
        get "/campaigns/#{campaign.slug}/refresh"

        expect(response).to redirect_to(overview_campaign_path(campaign.slug))
        expect(flash[:notice]).to eq('Campaign stats refreshed successfully')

        expect(Rails.cache.read(key)).to be_nil
      ensure
        Rails.cache = original_cache
      end
    end

    it 'returns 404 if campaign does not exists' do
      get '/campaigns/non-existent-slug/refresh'
      expect(response.status).to eq(404)
    end
  end
end
