# frozen_string_literal: true
require 'rails_helper'

cached_default_course_type = ENV['default_course_type']

def fill_out_open_course_creator_form
  fill_in 'Program title:', with: '한국어'
  fill_in 'Institution:', with: 'العَرَبِية'
  find('input[placeholder="Start date (YYYY-MM-DD)"]').set(Date.new(2017, 1, 4))
  find('input[placeholder="End date (YYYY-MM-DD)"]').set(Date.new(2017, 2, 1))
  page.find('body').click
end

describe 'open course creation', type: :feature, js: true do
  let(:user) { create(:user) }
  before do
    ENV['default_course_type'] = 'BasicCourse'
    Capybara.current_driver = :poltergeist
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
    fill_out_open_course_creator_form
    fill_in 'Home language:', with: 'ta'
    fill_in 'Home project', with: 'wiktionary'
    click_button 'Create my Program!'
    expect(page).to have_content 'This project has been published!'
    expect(Course.last.cohorts.count).to eq(1)
    expect(Course.last.home_wiki.language).to eq('ta')
    expect(Course.last.home_wiki.project).to eq('wiktionary')
  end

  it 'defaults to English Wikipedia' do
    visit root_path
    click_link 'Create a New Program'
    fill_out_open_course_creator_form
    click_button 'Create my Program!'
    expect(page).to have_content 'This project has been published!'
    expect(Course.last.cohorts.count).to eq(1)
    expect(Course.last.home_wiki.language).to eq('en')
    expect(Course.last.home_wiki.project).to eq('wikipedia')
  end

  it 'enables the "find your program" button' do
    visit root_path
    click_link 'Find a Program'
    page.find('section#courses')
  end
end
