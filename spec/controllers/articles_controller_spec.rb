# frozen_string_literal: true

require 'rails_helper'

describe ArticlesController, type: :request do
  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:second_user) { create(:user, username: 'SecondUser') }
  let(:course) { create(:course, start: Time.zone.now, end: Time.zone.now + 1.week) }

  before do
    create(:courses_user, user_id: user.id, course_id: course.id)
    create(:courses_user, user_id: second_user.id, course_id: course.id)
    create(:articles_course, course_id: course.id, article_id: article.id,
                             user_ids: [user.id, second_user.id])
  end

  describe '#revision_score' do
    it 'returns wp10 scores for the posted revision ids' do
      allow_any_instance_of(LiftWingApi).to receive(:get_revision_data)
        .and_return('1001' => { 'wp10' => 0.42 })
      post "/articles/#{article.id}/revision_score", params: { rev_ids: [1001], format: :json }
      expect(assigns(:article)).to eq(article)
      expect(Oj.load(response.body)).to eq('1001' => 0.42)
    end

    it 'scores no more revisions than the article graph asks for' do
      allow_any_instance_of(LiftWingApi).to receive(:get_revision_data).and_return({})
      post "/articles/#{article.id}/revision_score",
           params: { rev_ids: (1..200).to_a, format: :json }
      expect(Oj.load(response.body).size).to eq(ArticlesController::MAX_SCORED_REVISIONS)
    end
  end

  describe '#details' do
    let(:request_params) { { article_id: article.id, course_id: course.id, format: :json } }

    it 'sets the article and coursefrom the ids' do
      get '/articles/details', params: request_params
      expect(assigns(:article)).to eq(article)
      expect(assigns(:course)).to eq(course)
    end

    it 'sets the list of editors' do
      get '/articles/details', params: request_params
      expect(assigns(:article)).to eq(article)
      expect(assigns(:course)).to eq(course)
      json_response = Oj.load(response.body)
      expect(json_response['article_details']['editors']).to include(user.username)
      expect(json_response['article_details']['editors']).to include(second_user.username)
    end

    it 'only tracks the revisions of tracked articles' do
      ArticlesCourses.first.update(tracked: false)
      get '/articles/details', params: request_params
      json_response = Oj.load(response.body)
      expect(json_response['article_details']['editors'].count).to eq(0)
      ArticlesCourses.first.update(tracked: true)
      get '/articles/details', params: request_params
      json_response = Oj.load(response.body)
      expect(json_response['article_details']['editors'].count).to eq(2)
    end
  end

  describe '#update_tracked_status' do
    let(:instructor) { create(:user, username: 'Instructor') }
    let(:request_params) { { article_id: article.id, course_id: course.id, tracked: false } }
    let(:article_course) { course.articles_courses.find_by(article_id: article.id) }

    before do
      create(:courses_user, user_id: instructor.id, course_id: course.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    it 'updates the tracked status' do
      login_as instructor
      post '/articles/status', params: request_params, as: :json
      expect(article_course.reload.tracked).to eq(false)
      request_params[:tracked] = true
      post '/articles/status', params: request_params, as: :json
      expect(article_course.reload.tracked).to eq(true)
    end

    it 'refuses a logged-out visitor' do
      post '/articles/status', params: request_params, as: :json
      expect(response.status).to eq(401)
      expect(article_course.reload.tracked).to eq(true)
    end

    it 'refuses a student in the course' do
      login_as user
      post '/articles/status', params: request_params, as: :json
      expect(response.status).to eq(401)
      expect(article_course.reload.tracked).to eq(true)
    end
  end

  describe 'a private course' do
    let(:details_params) { { article_id: article.id, course_id: course.id, format: :json } }

    before { course.update(private: true) }

    it 'hides article details from a logged-out visitor' do
      get '/articles/details', params: details_params
      expect(response.status).to eq(404)
    end

    it 'shows article details to a participant' do
      login_as user
      get '/articles/details', params: details_params
      expect(response.status).to eq(200)
    end
  end
end
