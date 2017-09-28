# frozen_string_literal: true

require 'rails_helper'

describe ArticlesController do
  render_views

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
  end

  describe '#article_data' do
    it 'sets the article from the id' do
      get :article_data, params: { article_id: article.id }, format: :json
      expect(assigns(:article)).to eq(article)
    end
  end

  describe '#details' do
    it 'sets the article and coursefrom the ids' do
      get :details, params: { article_id: article.id, course_id: course.id }, format: :json
      expect(assigns(:article)).to eq(article)
      expect(assigns(:course)).to eq(course)
    end

    it 'sets the first revision, last revision, and list of editors' do
      get :details, params: { article_id: article.id, course_id: course.id }, format: :json
      expect(assigns(:article)).to eq(article)
      expect(assigns(:course)).to eq(course)
      json_response = JSON.parse(response.body)
      expect(json_response['article_details']['first_revision']['mw_rev_id'])
        .to eq(revision1.mw_rev_id)
      expect(json_response['article_details']['last_revision']['mw_rev_id'])
        .to eq(revision2.mw_rev_id)
      expect(json_response['article_details']['editors']).to include(user.username)
      expect(json_response['article_details']['editors']).to include(second_user.username)
    end
  end
end
