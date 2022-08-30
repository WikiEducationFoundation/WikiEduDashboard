# frozen_string_literal: true

require 'rails_helper'

describe 'Admin users', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:instructor) { create(:user, username: 'Professor Sage') }

  let(:submitted_course) do
    create(:course,
           title: 'My Submitted Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: true,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2025-01-01'.to_date)
  end
  let(:unsubmitted_course) do
    create(:course,
           title: 'My Unsubmitted Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course2_(Term)',
           submitted: false,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2025-01-01'.to_date)
  end

  let!(:fall_campaign) do
    create(:campaign, title: 'Fall 2015', created_at: Time.zone.now + 2.minutes)
  end
  let!(:spring_campaign) do
    create(:campaign, title: 'Spring 2016', created_at: Time.zone.now + 4.minutes)
  end

  before do
    page.current_window.resize_to(1920, 1080)

    create(:courses_user,
           user: instructor,
           course: submitted_course,
           role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:courses_user,
           user_id: instructor,
           course_id: unsubmitted_course,
           role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

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

      visit "/courses/#{submitted_course.slug}"
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
             campaign: fall_campaign,
             course: submitted_course)
      visit "/courses/#{submitted_course.slug}"
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
      visit "/courses/#{submitted_course.slug}"
      click_button('Edit Details')
      within '.pop__container.tags' do
        click_button '+'
        find('input').send_keys('My Tag', :enter)
        click_button 'Add'
      end

      sleep 1
      visit "/courses/#{submitted_course.slug}"
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
      visit "/courses/#{submitted_course.slug}"
      sleep 2
      expect(page).not_to have_content 'My Tag'
    end
  end

  describe 'linking a course to its Salesforce record' do
    it 'enables the Open and Update features' do
      stub_token_request
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)

      visit "/courses/#{submitted_course.slug}"
      expect(page).to have_button 'Link to Salesforce'
      accept_prompt(with: 'https://cs54.salesforce.com/a0f1a011101Xyas?foo=bar') do
        click_button 'Link to Salesforce'
      end
      expect(page).to have_content 'Open in Salesforce'
      expect(submitted_course.reload.flags[:salesforce_id]).to eq('a0f1a011101Xyas')

      expect(PushCourseToSalesforce).to receive(:new)
      accept_confirm do
        click_button 'Update Salesforce record'
      end
    end
  end

  describe 'admin quick actions' do
    before do
      JoinCourse.new(user: admin, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE,
                     course: submitted_course)
    end

    it 'clicking "Greet Students" schedules a GreetStudents worker' do
      stub_token_request
      expect(GreetStudentsWorker).to receive(:schedule_greetings)
      visit "/courses/#{submitted_course.slug}"
      accept_confirm do
        click_button 'Greet students'
      end
    end

    it 'clicking "Mark as Reviewed" updates the last-reviewed timestamp' do
      stub_token_request
      expect(UpdateCourseWorker).to receive(:schedule_edits)
      visit "/courses/#{submitted_course.slug}"
      expect(page).not_to have_content 'Last Reviewed:'
      click_button 'Mark as Reviewed'
      expect(page).to have_content 'Last Reviewed:'
    end
  end
end
