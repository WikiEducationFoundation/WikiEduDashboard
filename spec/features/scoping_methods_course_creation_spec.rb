# frozen_string_literal: true
require 'rails_helper'

describe 'Course creation for Article Scoped Programs', type: :feature, js: true do
  before do
    TrainingModule.load_all
    stub_oauth_edit

    user = create(:user,
                  id: 1,
                  permissions: User::Permissions::INSTRUCTOR)
    create(:training_modules_users, user_id: user.id,
                                    training_module_id: 3,
                                    completed_at: Time.zone.now)
    allow(Features).to receive(:wiki_ed?).and_return(false)
    allow(Features).to receive(:open_course_creation?).and_return(true)
    allow(Features).to receive(:default_course_string_prefix).and_return('courses_generic')
    login_as(user, scope: :user)

    visit root_path
    click_link 'Create an Independent Program'
    expect(page).to have_content 'Create an Independent Program'
    find('h4', text: 'Article Scoped Program').click
    find('#course_title').set('Course')
    find('#course_school').set('University')
    find('#course_description').set('My course')
    click_button 'Next'

    start_date = '2015-01-01'
    end_date = '2015-12-15'
    find('#course_start').set(start_date)
    find('#course_end').set(end_date)
    find('div.wizard__panel').click
    click_button 'Next'

    expect(page).to have_content 'Configure Scoping Methods'
    expect(page).to have_content 'Categories'
    expect(page).to have_content 'PagePile'
    expect(page).to have_content 'PetScan'
    expect(page).to have_content 'Templates'
  end

  after do
    logout
  end

  it 'lets a user skip configuring scoping methods' do
    click_button 'Create my Program!'

    expect(page).to have_content 'My course'
    expect(page).to have_content 'Course'
    expect(page).to have_content 'This project has been published!'
    expect(Course.all.count).to eq(1)
  end

  it 'lets a user configure categories' do
    find('h4', text: 'Categories').click
    expect(page).to have_selector('.scoping-method-types .selected', count: 1)
    expect(page).not_to have_content 'Create my Program!'
    click_button 'Next'

    find(:css, '#categories input').set('Earth ')
    find(:css, '#categories div[class*="option"]', text: 'Earth sciences').click

    expect(page).to have_content 'Earth sciences'
    expect(page).to have_content 'Create my Program!'
    click_button 'Create my Program!'

    expect(page).to have_content 'My course'
    expect(page).to have_content 'Course'
    expect(page).to have_content 'This project has been published!'
    expect(Course.all.count).to eq(1)

    click_link 'Articles'
    expect(page).to have_content 'Earth_sciences'
  end

  it 'lets a user configure templates' do
    find('h4', text: 'Templates').click
    expect(page).to have_selector('.scoping-method-types .selected', count: 1)
    expect(page).not_to have_content 'Create my Program!'
    click_button 'Next'

    find(:css, '#templates input').set('Earth ')
    find(:css, '#templates div[class*="option"]', text: 'Earth mass').click

    expect(page).to have_content 'Earth mass'
    expect(page).to have_content 'Create my Program!'
    click_button 'Create my Program!'

    expect(page).to have_content 'My course'
    expect(page).to have_content 'Course'
    expect(page).to have_content 'This project has been published!'
    expect(Course.all.count).to eq(1)

    click_link 'Articles'
    expect(page).to have_content 'Earth_mass'
  end

  it 'lets a user configure multiple scoping methods' do
    find('h4', text: 'Templates').click
    find('h4', text: 'Categories').click
    find('h4', text: 'PetScan').click

    expect(page).to have_selector('.scoping-method-types .selected', count: 3)
    expect(page).not_to have_content 'Create my Program!'
    click_button 'Next'

    expect(page).to have_content 'Categories'
    find(:css, '#categories input').set('Earth ')
    find(:css, '#categories div[class*="option"]', text: 'Earth sciences').click

    expect(page).to have_content 'Earth sciences'
    expect(page).not_to have_content 'Create my Program!'
    click_button 'Next'

    expect(page).to have_content 'PetScan'
    find(:css, '.scoping-method-petscan input').set('111')
    find(:css, '.scoping-method-petscan input').native.send_keys(:tab)

    expect(page).to have_content '111'
    expect(page).not_to have_content 'Create my Program!'
    click_button 'Next'

    expect(page).to have_content 'Templates'
    find(:css, '#templates input').set('Earth ')
    find(:css, '#templates div[class*="option"]', text: 'Earth mass').click

    expect(page).to have_content 'Earth mass'
    expect(page).to have_content 'Create my Program!'
    click_button 'Create my Program!'

    expect(page).to have_content 'My course'
    expect(page).to have_content 'Course'
    expect(page).to have_content 'This project has been published!'
    expect(Course.all.count).to eq(1)

    click_link 'Articles'
    expect(page).to have_content 'Earth_mass'
    expect(page).to have_content 'Earth_sciences'
    expect(page).to have_content 'Psid:111'
  end
end
