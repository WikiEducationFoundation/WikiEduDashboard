# frozen_string_literal: true

require 'rails_helper'

describe 'Admin users', type: :feature, js: true do
  before do
    page.current_window.resize_to(1920, 1080)
    page.driver.browser.url_blacklist = ['https://wikiedu.org']
  end

  before :each do
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
           end: '2020-01-01'.to_date)
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
           end: '2020-01-01'.to_date)
    create(:courses_user,
           user_id: 100,
           course_id: 10002,
           role: 1)

    create(:campaign, id: 1, title: 'Fall 2015',
                      created_at: Time.now + 2.minutes)
    create(:campaign, id: 2, title: 'Spring 2016',
                      created_at: Time.now + 4.minutes)

    user = create(:admin,
                  id: 200,
                  wiki_token: 'foo',
                  wiki_secret: 'bar')
    login_as(user, scope: :user)
  end

  describe 'visiting the dashboard' do
    it 'should see submitted courses awaiting approval' do
      visit root_path
      sleep 1
      expect(page).to have_content 'Submitted & Pending Approval'
      expect(page).to have_content 'My Submitted Course'
    end
  end

  describe 'adding a course to a campaign' do
    it 'should make the course live' do
      stub_oauth_edit
      stub_chat_channel_create_success

      visit "/courses/#{Course.first.slug}"
      sleep 1

      # Edit details and add campaign
      click_button('Edit Details')

      page.all('.button.border.plus')[4].click

      # Ensure campaigns appear in select list ordered by time (descending)
      campaign_options = all('select[name=campaign]>option')[1, 2]
      expect(campaign_options[0]).to have_text Campaign.find(2).title
      expect(campaign_options[1]).to have_text Campaign.find(1).title

      select 'Fall 2015', from: 'campaign'
      find('.pop button', visible: true).click
      sleep 1

      expect(page).to have_content 'Your course has been published'

      visit root_path
      sleep 1
      expect(page).not_to have_content 'Submitted & Pending Approval'
    end
  end

  describe 'removing all campaigns from a course' do
    it 'returns it to "submitted" status' do
      pending 'This sometimes fails on travis.'

      stub_oauth_edit
      create(:campaigns_course,
             campaign_id: 1,
             course_id: 10001)
      visit "/courses/#{Course.first.slug}"
      sleep 1

      expect(page).to have_content 'Your course has been published'

      # Edit details and remove campaign
      click_button('Edit Details')
      page.all('.button.border.plus')[4].click
      page.find('.button.border.plus', text: '-').click
      sleep 1

      expect(page).to have_content 'This course has been submitted'

      visit root_path
      sleep 1
      expect(page).to have_content 'Submitted & Pending Approval'

      puts 'PASSED'
      raise 'this test passed — this time'
    end
  end

  describe 'adding a tag to a course' do
    it 'should work' do
      stub_token_request
      visit "/courses/#{Course.first.slug}"
      sleep 1

      click_button('Edit Details')
      within '.tags' do
        page.find('.button.border.plus').click
        page.find('input').set 'My Tag'
        find('.pop button', visible: true).click
      end

      sleep 1
      visit "/courses/#{Course.first.slug}"
      sleep 1
      expect(page).to have_content 'My Tag'

      # Add the same tag again
      click_button('Edit Details')
      within('div.tags') do
        page.find('.button.border.plus').click
      end
      page.find('section.overview input[placeholder="Tag"]').set 'My Tag'
      page.all('.pop button', visible: true)[1].click

      # Delete the tag
      within('div.tags') do
        click_button '-'
      end
      sleep 1
      visit "/courses/#{Course.first.slug}"
      sleep 1
      expect(page).not_to have_content 'My Tag'
    end
  end

  describe 'linking a course to its Salesforce record' do
    it 'makes the Link to Salesforce button appear' do
      pending 'This sometimes fails on travis.'

      stub_token_request
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)

      visit "/courses/#{Course.first.slug}"
      accept_prompt(with: 'https://cs54.salesforce.com/a0f1a011101Xyas?foo=bar') do
        click_button 'Link to Salesforce'
      end
      expect(page).to have_content 'Open in Salesforce'
      expect(Course.first.flags[:salesforce_id]).to eq('a0f1a011101Xyas')

      puts 'PASSED'
      raise 'this test passed — this time'
    end
  end

  after do
    logout
  end
end
