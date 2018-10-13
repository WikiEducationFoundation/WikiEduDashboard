# frozen_string_literal: true

require 'rails_helper'

describe 'course deletion', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin) }

  it 'destroys the course and redirects to the home page' do
    login_as admin
    stub_oauth_edit
    visit "/courses/#{course.slug}"

    expect(Course.count).to eq(1)

    accept_prompt(with: course.title) do
      click_button 'Delete course'
    end
    expect(page).to have_content 'Create Course'
    expect(Course.count).to eq(0)
  end
end
