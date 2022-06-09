# frozen_string_literal: true

require 'rails_helper'

describe 'Instructor users', type: :feature, js: true do
  before do
    include type: :feature
    include Devise::TestHelpers
    TrainingModule.load_all
    page.current_window.resize_to(1920, 1080)
    instructor = create(:user,
                        id: 100,
                        username: 'Professor Sage',
                        wiki_token: 'foo',
                        wiki_secret: 'bar')

    create(:user,
           id: 101,
           username: 'Student A')
    create(:user,
           id: 102,
           username: 'Student B')
    create(:course,
           id: 10001,
           title: 'My Active Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: true,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2020-01-01'.to_date,
           user_count: 2,
           trained_count: 0)
    create(:courses_user,
           id: 1,
           user_id: 100,
           course_id: 10001,
           role: 1)
    create(:courses_user,
           id: 2,
           user_id: 101,
           course_id: 10001,
           real_name: 'Really Real Name',
           role: 0)
    create(:courses_user,
           id: 3,
           user_id: 102,
           course_id: 10001,
           real_name: 'Another Actual Name',
           role: 0)
    create(:campaign,
           id: 1,
           title: 'Fall 2015')
    create(:campaigns_course,
           campaign_id: 1,
           course_id: 10001)

    login_as(instructor, scope: :user)
    stub_oauth_edit
    stub_raw_action
    stub_info_query
  end

  after do
    logout
  end

  describe 'visiting the home tab' do
    it 'can see the passcode' do
      visit "/courses/#{Course.first.slug}"
      expect(page).to have_content('passcode')
      expect(page).not_to have_content('****')
    end
  end

  describe 'visiting the students page' do
    let(:week) { create(:week, course_id: Course.first.id) }
    let(:tm) { TrainingModule.all.first }
    let!(:block) do
      create(:block, week_id: week.id, training_module_ids: [tm.id], due_date: Time.zone.today)
    end

    before do
      TrainingModulesUsers.destroy_all
      travel(1.year)
    end

    after do
      travel_back
    end

    it 'can see real names of enrolled students' do
      visit "/courses/#{Course.first.slug}/students/overview"
      expect(page).to have_content('Really Real Name')
    end

    it 'is able to add students' do
      allow_any_instance_of(WikiApi).to receive(:get_user_info).and_return(
        'name' => 'Risker', 'userid' => 123, 'centralids' => { 'CentralAuth' => 456 }
      )
      visit "/courses/#{Course.first.slug}/students/overview"
      click_button 'Add/Remove Students'
      within('#users') { all('input')[1].set('Risker') }
      click_button 'Enroll'
      click_button 'OK'

      expect(page).to have_content 'Risker was added successfully'
    end

    it 'is not able to add nonexistent users as students' do
      allow_any_instance_of(WikiApi).to receive(:get_user_id).and_return(nil)
      visit "/courses/#{Course.first.slug}/students/overview"
      click_button 'Add/Remove Students'
      within('#users') { all('input')[1].set('NotARealUser') }
      click_button 'Enroll'
      click_button 'OK'
      expect(page).to have_content 'NotARealUser is not an existing user on en.wikipedia.org.'
    end

    it 'is able to remove students' do
      visit "/courses/#{Course.first.slug}/students/overview"
      click_button 'Add/Remove Students'
      sleep 1
      # Remove a user
      page.all('button.border.plus')[1].click
      click_button 'OK'
      sleep 1
      visit "/courses/#{Course.first.slug}/students"
      expect(page).to have_content 'Student A'
      expect(page).not_to have_content 'Student B'
    end

    it 'is able to assign articles' do
      pending 'This sometimes fails on travis.'

      visit "/courses/#{Course.first.slug}/students/articles"

      # Assign an article
      click_button 'Assign Articles'
      find('button.border', text: 'Assign/remove an article', match: :first).click
      within('#users') { find('input', match: :first).set('Article 1') }
      click_button 'Assign'
      click_button 'OK'
      find('button.border.assign-button', match: :first).click

      # Assign a review
      find('button.border', text: 'Assign/remove a peer review', match: :first).click
      sleep 1
      within('#users') { find('input', match: :first).set('Article 2') }
      click_button 'Assign'
      click_button 'OK'
      find('button.border.assign-button', match: :first).click

      # Leave editing mode
      within 'div.controls' do
        click_button 'Done'
      end
      expect(page).to have_content 'Article 1'
      expect(page).to have_content 'Article 2'

      # Delete an assignments
      visit "/courses/#{Course.first.slug}/students/articles"
      sleep 1
      click_button 'Assign Articles'
      find('button.border.assign-button', match: :first).click
      page.accept_confirm do
        click_button '-'
      end
      sleep 1
      within 'div.controls' do
        click_button 'Done'
      end
      expect(page).not_to have_content 'Article 1'

      pass_pending_spec
    end

    it 'is able to remove students from the course' do
      pending 'This sometimes fails on travis.'

      visit "/courses/#{Course.first.slug}/students/overview"

      click_button 'Add/Remove Students'
      find('button.border.plus', text: '-', match: :first).click
      click_button 'OK'
      sleep 1
      expect(page).not_to have_content 'Student A'

      pass_pending_spec
    end

    it 'is able to notify users with overdue training' do
      visit "/courses/#{Course.first.slug}/students/overview"

      sleep 1
      # Notify users with overdue training
      accept_alert do
        accept_confirm do
          find('button.notify_overdue').click
        end
      end
    end
  end
end
