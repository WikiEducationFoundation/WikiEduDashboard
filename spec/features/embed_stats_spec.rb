# frozen_string_literal: true

require 'rails_helper'

describe 'course stats embed page', type: :feature, js: true do
  let(:course) { create(:course) }

  it 'returns does nothing if token is incorrect' do
    visit "/embed/course_stats/#{course.slug}"
    expect(page).to have_content 'Articles Edited'
  end
end
