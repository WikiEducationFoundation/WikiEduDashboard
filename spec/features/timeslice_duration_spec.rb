# frozen_string_literal: true

require 'rails_helper'

describe 'timeslice duration admin page', type: :feature, js: true do
  let(:super_admin) { create(:super_admin) }
  let(:course) { create(:course) }

  before { login_as(super_admin) }
  after { logout }

  it 'index loads cleanly' do
    visit '/timeslice_duration'
    expect(page).to have_content 'View and update timeslice duration'
    expect(page).to be_axe_clean
  end

  it 'update results page loads cleanly' do
    visit "/timeslice_duration/update?course_id=#{course.id}"
    expect(page).to have_content 'Results'
    expect(page).to be_axe_clean
  end
end
