# frozen_string_literal: true

require 'rails_helper'

describe StyleguideController, type: :request do
  it 'renders without error' do
    get '/styleguide'
    expect(response.status).to eq(200)
  end
end
