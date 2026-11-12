# frozen_string_literal: true

require 'rails_helper'

describe 'GET /all_courses.json', type: :request do
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
    create(:course, id: 1, school: 'University of Washington, Bothell',
                    start: 1.year.ago, end: 1.day.from_now)
  end

  it 'reports the institution name for the course' do
    get '/all_courses.json'
    expect(JSON.parse(response.body)['all_courses'].first['institution'])
      .to eq('University of Washington, Bothell')
  end
end
