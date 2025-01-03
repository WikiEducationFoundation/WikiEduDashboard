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

    it 'adds the given user as an organizer of the campaign '\
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

    it 'removes the given organizer from the campaign '\
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

  describe '#students' do
    let(:course) { create(:course) }
    let(:campaign) { create(:campaign) }
    let(:student) { create(:user) }

    before do
      login_as build(:user)
      campaign.courses << course
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    after do
      FileUtils.remove_dir('public/system/analytics')
    end

    context 'without "course" option' do
      let(:request_params) { { slug: campaign.slug, format: :csv } }

      it 'returns a csv of student usernames' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get "/campaigns/#{campaign.slug}/students", params: request_params
        expect(response.body).to include('file is being generated')
        get "/campaigns/#{campaign.slug}/students", params: request_params
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include(student.username)
      end
    end

    context 'with "course" option' do
      let(:request_params) { { slug: campaign.slug, course: true, format: :csv } }

      it 'returns a csv of student usernames with course slugs' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get "/campaigns/#{campaign.slug}/students", params: request_params
        expect(response.body).to include('file is being generated')
        get "/campaigns/#{campaign.slug}/students", params: request_params
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include(student.username)
        expect(csv).to include(course.slug)
      end
    end
  end

  describe '#instructors' do
    let(:course) { create(:course) }
    let(:campaign) { create(:campaign) }
    let(:instructor) { create(:user) }

    before do
      login_as instructor
      campaign.courses << course
      create(:courses_user, course_id: course.id, user_id: instructor.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    after do
      FileUtils.remove_dir('public/system/analytics')
    end

    context 'without "course" option' do
      let(:request_params) { { slug: campaign.slug, format: :csv } }

      it 'returns a csv of instructor usernames' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get "/campaigns/#{campaign.slug}/instructors", params: request_params
        expect(response.body).to include('file is being generated')
        get "/campaigns/#{campaign.slug}/instructors", params: request_params
        follow_redirect!
        expect(response.body).to include(instructor.username)
      end
    end

    context 'with "course" option' do
      let(:request_params) { { slug: campaign.slug, course: true, format: :csv } }

      it 'returns a csv of instructor usernames with course slugs' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get "/campaigns/#{campaign.slug}/instructors", params: request_params
        expect(response.body).to include('file is being generated')
        get "/campaigns/#{campaign.slug}/instructors", params: request_params
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include(instructor.username)
        expect(csv).to include(course.slug)
      end
    end
  end

  describe '#courses' do
    let(:course) { create(:course, user_count: 1) }
    let(:campaign) { create(:campaign) }
    let(:instructor) { create(:user) }
    let(:request_params) { { slug: campaign.slug, format: :csv } }

    before do
      login_as instructor
      campaign.courses << course
      create(:courses_user, course_id: course.id, user_id: instructor.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    after do
      FileUtils.remove_dir('public/system/analytics')
    end

    it 'returns a csv of course data' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get "/campaigns/#{campaign.slug}/courses", params: request_params
      get "/campaigns/#{campaign.slug}/courses", params: request_params
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include(course.slug)
      expect(csv).to include(course.title)
      expect(csv).to include(course.school)
    end

    it 'cleans up the files afterwards' do
      # This normally happens long afterwards, but in test mode
      # sidekiq will execute all jobs immediately, so the file
      # will be created and immediately deleted.
      expect(CsvCleanupWorker).to receive(:perform_at).and_call_original
      get "/campaigns/#{campaign.slug}/courses", params: request_params
      expect(response.body).to include('file is being generated')
    end
  end

  describe 'CSV actions' do
    let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
    let(:course) { create(:course) }
    let(:another_course) { create(:course, home_wiki: wikidata, slug: 'campaign/acourse') }
    let(:campaign) { create(:campaign) }
    let(:article) { create(:article) }
    let(:user) { create(:user) }
    let!(:revision) { create(:revision, article:, user:, date: course.start + 1.hour) }
    let!(:course_stats) do
      create(:course_stats, stats_hash: { 'www.wikidata.org' => {
               'claims created' => 12, 'other updates' => 1, 'unknown' => 1
             } },
             course:)
    end
    let(:request_params) { { slug: campaign.slug, format: :csv } }

    before do
      stub_wiki_validation
      login_as(user)
      campaign.courses.push course, another_course
      create(:courses_user, course:, user:)
    end

    after do
      FileUtils.remove_dir('public/system/analytics')
    end

    it 'return a csv of article data' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get "/campaigns/#{campaign.slug}/articles_csv", params: request_params
      get "/campaigns/#{campaign.slug}/articles_csv", params: request_params
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include(course.slug)
      expect(csv).to include(article.title)
    end

    it 'returns a csv of wikidata' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get "/campaigns/#{campaign.slug}/wikidata.csv"
      get "/campaigns/#{campaign.slug}/wikidata.csv"
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include('course name,claims created')
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
end
