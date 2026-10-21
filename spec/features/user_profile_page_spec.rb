# frozen_string_literal: true

require 'rails_helper'

describe 'user profile pages', type: :feature, js: true do
  let(:user) { create(:user, username: 'Sage') }
  let(:course) { create(:course) }
  let(:course2) { create(:course, slug: 'course/2') }
  let(:article) { create(:article) }

  before do
    create(:courses_user, user:, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user, user:, course: course2, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:articles_course, course:, article:)
  end

  it 'lets the user update their own email and other info' do
    login_as user
    visit "/users/#{user.username}"
    click_button 'Edit Details'
    expect(page).to have_button 'Save'
    expect(page).to have_button 'Cancel'
    expect(page).to have_no_button 'Edit Details'
    fill_in 'email_email', with: 'tester@wikiedu.org'
    fill_in 'user_profile_bio', with: 'Wikipedian from Seattle'
    click_button 'Save'
    expect(page).to have_button 'Edit Details'
    expect(page).to have_content 'tester@wikiedu.org'
  end

  it 'lets the user edit profile location and institution' do
    create(:user_profile, user: user, location: 'São Paulo', institution: 'WMF Brasil')

    login_as user
    visit "/users/#{user.username}"
    click_button 'Edit Details'

    expect(page).to have_field('user_profile_location', with: 'São Paulo')
    expect(page).to have_field('user_profile_institution', with: 'WMF Brasil')

    fill_in 'user_profile_location', with: 'Rio de Janeiro'
    fill_in 'user_profile_institution', with: 'WikiMedia Brasil'
    click_button 'Save'

    expect(page).to have_content 'Rio de Janeiro'
    expect(page).to have_content 'WikiMedia Brasil'
  end

  it 'shows contribution statistics' do
    visit "/users/#{user.username}"
    expect(page).to have_content 'Total impact made by Sage as an instructor'
    expect(page).to have_content "Total impact made by Sage's students"
    expect(page).to have_content 'Total impact made by Sage as a student'
    expect(page).to be_axe_clean
  end

  it 'supports nested profile routes and navigation under the user path' do
    visit "/users/#{user.username}"
    expect(page).to have_link('Contribution Statistics', href: "/users/#{user.username}")
    expect(page).to have_link('Course Details', href: "/users/#{user.username}/course-details")
    expect(page).to have_link('Recent Uploads', href: "/users/#{user.username}/uploads")
    expect(page).to have_link('Training Status', href: "/users/#{user.username}/training")

    click_link 'Course Details'
    expect(page).to have_content 'Course Details'
    expect(page).to have_link('Back to Profile', href: "/users/#{user.username}")
  end

  context 'when username contains special characters' do
    let(:qmark_user) { create(:user, username: 'Example?User') }
    let(:qmark_course) { create(:course, slug: 'qmark/course') }
    let(:qmark_article) { create(:article, title: 'Special_article') }

    before do
      create(:courses_user, user: qmark_user, course: qmark_course,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:articles_course, course: qmark_course, article: qmark_article,
                               user_ids: [qmark_user.id])
    end

    it 'encodes username properly in sub-routes and detail links' do
      visit '/users/Example%3FUser'
      expect(page).to have_link('Course Details', href: '/users/Example%3FUser/course-details')
      find('.user-stats-table tbody tr', text: 'Articles Edited').click_link 'See more ↗'
      expect(page).to have_content 'Articles Edited'
      expect(page).to have_content qmark_article.title
      expect(page).to have_link('Back to Profile', href: '/users/Example%3FUser')
    end
  end

  context 'when user has done training(s)' do
    before do
      TrainingModule.load
      create(:training_modules_users, user:, training_module_id: TrainingModule.first.id,
                                      completed_at: Time.zone.now)
    end

    it 'shows training status (to that user)' do
      login_as user
      visit "/users/#{user.username}/training"
      expect(page).to have_content TrainingModule.first.name
      expect(page).to have_content 'Completed at'
      expect(page).to have_link('Back to Profile', href: "/users/#{user.username}")
    end
  end
end