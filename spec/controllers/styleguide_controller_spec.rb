# frozen_string_literal: true

require 'rails_helper'

describe StyleguideController do
  render_views

  it 'renders without error' do
    get :index
    expect(response.status).to eq(200)
  end
end
