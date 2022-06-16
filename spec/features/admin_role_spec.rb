# frozen_string_literal: true

require 'rails_helper'

describe 'Admin users', type: :feature, js: true do
  let(:admin) { create(:admin) }

  before do
    page.current_window.resize_to(1920, 1080)
    create(:user,
           id: 100,
           username: 'Professor Sage')

    create(:course,
           id: 10001,
           title: 'My Submitted Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: true,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2025-01-01'.to_date)
    create(:courses_user,
           user_id: 100,
           course_id: 10001,
           role: 1)

    create(:course,
           id: 10002,
           title: 'My Unsubmitted Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course2_(Term)',
           submitted: false,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2025-01-01'.to_date)
    create(:courses_user,
           user_id: 100,
           course_id: 10002,
           role: 1)

    create(:campaign, id: 1, title: 'Fall 2015',
                      created_at: Time.zone.now + 2.minutes)
    create(:campaign, id: 2, title: 'Spring 2016',
                      created_at: Time.zone.now + 4.minutes)

    login_as(admin)
  end

  after do
    logout
  end

  describe 'visiting the dashboard' do
    it 'sees submitted courses awaiting approval' do
      visit root_path
      expect(page).to have_content 'Submitted & Pending Approval'
      expect(page).to have_content 'My Submitted Course'
    end
  end

  describe 'adding a course to a campaign' do
    it 'makes the course live' do
      stub_oauth_edit

      visit "/courses/#{Course.first.slug}"
      expect(page).to have_content 'This course has been submitted for approval by its creator'

      # Edit details and add campaign
      click_button 'Edit Details'
      within '#course_campaigns' do
        page.find('.button.border.plus').click
        find('input').send_keys('Fall 2015', :enter)
        click_button 'Add'
      end

      expect(page).to have_content 'Your course has been published'
      expect(page).not_to have_content 'This course has been submitted for approval by its creator'
    end
  end

  describe 'removing all campaigns from a course' do
    it 'returns it to "submitted" status' do
      stub_oauth_edit
      create(:campaigns_course,
             campaign_id: 1,
             course_id: 10001)
      visit "/courses/#{Course.first.slug}"
      expect(page).to have_content 'Your course has been published'

      # Edit details and remove campaign
      click_button('Edit Details')
      within '#course_campaigns' do
        omniclick find('button', text: '+')
        omniclick find('button', text: '-')
      end
      expect(page).to have_content 'This course has been submitted'

      visit root_path
      expect(page).to have_content 'Submitted & Pending Approval'
    end
  end

  describe 'adding a tag to a course' do
    it 'works' do
      stub_token_request
      visit "/courses/#{Course.first.slug}"
      click_button('Edit Details')
      within '.pop__container.tags' do
        click_button '+'
        find('input').send_keys('My Tag', :enter)
        click_button 'Add'
      end

      sleep 1
      visit "/courses/#{Course.first.slug}"
      expect(page).to have_content 'My Tag'

      # Add the same tag again
      click_button('Edit Details')
      within '.pop__container.tags' do
        click_button '+'
        find('input').send_keys('My Tag', :enter)
        click_button 'Add'

        # Delete the tag
        click_button '-'
      end
      sleep 1
      visit "/courses/#{Course.first.slug}"
      sleep 2
      expect(page).not_to have_content 'My Tag'
    end
  end

  describe 'linking a course to its Salesforce record' do
    it 'enables the Open and Update features' do
      stub_token_request
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)

      visit "/courses/#{Course.first.slug}"
      expect(page).to have_button 'Link to Salesforce'
      accept_prompt(with: 'https://cs54.salesforce.com/a0f1a011101Xyas?foo=bar') do
        click_button 'Link to Salesforce'
      end
      expect(page).to have_content 'Open in Salesforce'
      expect(Course.first.flags[:salesforce_id]).to eq('a0f1a011101Xyas')

      expect(PushCourseToSalesforce).to receive(:new)
      accept_confirm do
        click_button 'Update Salesforce record'
      end
    end
  end

  describe 'clicking "Greet Students"' do
    before do
      JoinCourse.new(user: admin, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE,
                     course: Course.first)
    end

    it 'schedules a GreetStudents worker' do
      stub_token_request
      expect(GreetStudentsWorker).to receive(:schedule_greetings)
      visit "/courses/#{Course.first.slug}"
      accept_confirm do
        click_button 'Greet students'
      end
    end
  end
end
