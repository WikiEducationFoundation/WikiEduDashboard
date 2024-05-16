# frozen_string_literal: true

require 'rails_helper'

describe ArticlesController, type: :request do
  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:second_user) { create(:user, username: 'SecondUser') }
  let(:course) { create(:course) }
  let!(:revision1) do
    create(:revision, article_id: article.id, user_id: user.id,
                      date: course.start + 1.day, mw_rev_id: 123)
  end
  let!(:revision2) do
    create(:revision, article_id: article.id, user_id: second_user.id,
                      date: course.end - 1.day, mw_rev_id: 234)
  end

  before do
    create(:courses_user, user_id: user.id, course_id: course.id)
    create(:courses_user, user_id: second_user.id, course_id: course.id)
    create(:articles_course, course_id: course.id, article_id: article.id, user_ids: [user.id, second_user.id])
  end

  describe '#article_data' do
    it 'sets the article from the id' do
      get '/articles/article_data', params: { article_id: article.id, format: :json }
      expect(assigns(:article)).to eq(article)
    end
  end

  describe '#details' do
    let(:request_params) { { article_id: article.id, course_id: course.id, format: :json } }

    it 'sets the article and coursefrom the ids' do
      get '/articles/details', params: request_params
      expect(assigns(:article)).to eq(article)
      expect(assigns(:course)).to eq(course)
    end

    it 'sets the first revision, last revision, and list of editors' do
      get '/articles/details', params: request_params
      expect(assigns(:article)).to eq(article)
      expect(assigns(:course)).to eq(course)
      json_response = Oj.load(response.body)
      expect(json_response['article_details']['first_revision']['mw_rev_id'])
        .to eq(revision1.mw_rev_id)
      expect(json_response['article_details']['last_revision']['mw_rev_id'])
        .to eq(revision2.mw_rev_id)
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
    it 'updates the tracked status' do
      request_params = { article_id: article.id, course_id: course.id, tracked: false }
      article_course = course.articles_courses.find_by(article_id: article.id)
      post '/articles/status', params: request_params, as: :json
      expect(article_course.reload.tracked).to eq(false)
      request_params[:tracked] = true
      post '/articles/status', params: request_params, as: :json
      expect(article_course.reload.tracked).to eq(true)
    end
  end
end
