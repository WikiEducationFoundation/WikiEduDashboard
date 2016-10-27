# frozen_string_literal: true
require 'rails_helper'

describe ArticlesController do
  describe '#wp10' do
    let(:article) { create(:article) }
    it 'sets the article from the id' do
      get :wp10, params: { article_id: article.id }, format: :json
      expect(assigns(:article)).to eq(article)
    end
  end
end
