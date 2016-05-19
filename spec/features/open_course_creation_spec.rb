require 'rails_helper'

cached_default_course_type = ENV['default_course_type']

def fill_out_course_creator_form
  fill_in 'Program title:', with: 'My program'
  # fill_in 'Course term:', with: 'Spring 2016'
  fill_in 'Institution:', with: 'WikiProject Bonsai'
  find('input[placeholder="Start date (YYYY-MM-DD)"]').set(Date.new(2017, 1, 4))
  find('input[placeholder="End date (YYYY-MM-DD)"]').set(Date.new(2017, 2, 1))
  sleep 60
  click_button 'Create my Program!'
end

describe 'open course creation', type: :feature, js: true do
  let(:user) { create(:user) }
  before do
    ENV['default_course_type'] = 'BasicCourse'
    Capybara.current_driver = :selenium
    page.current_window.resize_to(1920, 1080)

    allow(Features).to receive(:open_course_creation?).and_return(true)
    allow(Features).to receive(:disable_wiki_output?).and_return(true)
    login_as(user)
  end

  after do
    ENV['default_course_type'] = cached_default_course_type
  end

  it 'lets a user create a course immediately' do
    visit root_path
    click_link 'Create a New Program'
    fill_out_course_creator_form
    expect(page).to have_content 'This project has been published!'
    expect(Course.last.cohorts.count).to eq(1)
  end

  it 'enables the "find your program" button' do
    visit root_path
    click_link 'Find a Program'
    page.find('section#courses')
  end
end
