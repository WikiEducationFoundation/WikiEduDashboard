require 'rails_helper'

cached_default_course_type = ENV['default_course_type']

describe 'open course creation', type: :feature, js: true do
  let(:user) { create(:user) }
  before do
    ENV['default_course_type'] = 'BasicCourse'
    Capybara.current_driver = :selenium
    page.current_window.resize_to(1920, 1080)

    allow(Features).to receive(:open_course_creation?).and_return(true)
    login_as(user)
  end

  after do
    ENV['default_course_type'] = cached_default_course_type
  end

  it 'lets a user create a course immediately' do
    visit root_path
    click_link 'Create a New Program'
    click_button 'Create my Program!'
  end

  it 'enables the "find your program" button' do
    visit root_path
    click_link 'Find a Program'
    page.find('section#courses')
  end
end
