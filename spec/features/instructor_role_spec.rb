require 'rails_helper'

describe 'Instructor users', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
    page.driver.browser.manage.window.resize_to(1920, 1920)
  end

  before :each do
    instructor = create(:user,
                        id: 100,
                        wiki_id: 'Professor Sage',
                        wiki_token: 'foo',
                        wiki_secret: 'bar')

    create(:user,
           id: 101,
           wiki_id: 'Student A')
    create(:user,
           id: 102,
           wiki_id: 'Student B')
    create(:course,
           id: 10001,
           title: 'My Active Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: 1,
           listed: true,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2020-01-01'.to_date)
    create(:courses_user,
           id: 1,
           user_id: 100,
           course_id: 10001,
           role: 1)
    create(:courses_user,
           id: 2,
           user_id: 101,
           course_id: 10001,
           role: 0)
    create(:courses_user,
           id: 3,
           user_id: 102,
           course_id: 10001,
           role: 0)
    create(:cohort,
           id: 1,
           title: 'Fall 2015')
    create(:cohorts_course,
           cohort_id: 1,
           course_id: 10001)

    login_as(instructor, scope: :user)
    stub_oauth_edit
    stub_raw_action
  end

  describe 'visiting the students page' do
    let(:week) { create(:week, course_id: Course.first.id) }
    let(:tm) { TrainingModule.all.first }
    let!(:block) do
      create(:block, week_id: week.id, training_module_ids: [tm.id], due_date: Date.today)
    end

    before do
      TrainingModulesUsers.destroy_all
      Timecop.travel(1.year.from_now)
    end

    after do
      Timecop.return
    end

    it 'should be able to add students' do
      allow(Wiki).to receive(:get_user_id).and_return(123)
      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      click_button 'Enrollment'
      within('#users') { all('input')[1].set('Risker') }
      click_button 'Enroll'
      page.driver.browser.switch_to.alert.accept
      page.driver.browser.switch_to.alert.accept
      expect(page).to have_content 'Risker'
    end

    it 'should not be able to add nonexistent users as students' do
      allow(Wiki).to receive(:get_user_id).and_return(nil)
      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      click_button 'Enrollment'
      within('#users') { all('input')[1].set('NotARealUser') }
      click_button 'Enroll'
      page.driver.browser.switch_to.alert.accept
      page.driver.browser.switch_to.alert.accept
      expect(page).not_to have_content 'NotARealUser'
    end

    it 'should be able to remove students' do
      visit "/courses/#{Course.first.slug}/students"
      sleep 1

      # Click the Enrollment button
      click_button 'Enrollment'
      sleep 1
      # Remove a user
      page.all('button.border.plus')[1].click
      sleep 1
      page.driver.browser.switch_to.alert.accept
      sleep 1

      visit "/courses/#{Course.first.slug}/students"
      expect(page).to have_content 'Student A'
      expect(page).not_to have_content 'Student B'
    end

    it 'should be able to assign articles' do
      visit "/courses/#{Course.first.slug}/students"
      sleep 1

      # Assign an article
      click_button 'Assign Articles'
      page.all('button.border')[0].click
      within('#users') { first('input').set('Article 1') }
      click_button 'Assign'
      page.driver.browser.switch_to.alert.accept
      sleep 1
      page.first('button.border.dark.plus').click
      sleep 1

      # Assign a review
      page.all('button.border')[1].click
      within('#users') { first('input').set('Article 2') }
      click_button 'Assign'
      page.driver.browser.switch_to.alert.accept
      sleep 1
      page.all('button.border.dark.plus')[0].click
      sleep 1

      # Save these assignments
      click_button 'Save'
      expect(page).to have_content 'Article 1'
      expect(page).to have_content 'Article 2'

      # Delete an assignments
      click_button 'Assign Articles'
      page.first('button.border.plus').click
      click_button '-'
      page.driver.browser.switch_to.alert.accept
      sleep 1
      click_button 'Save'
      expect(page).not_to have_content 'Article 1'
    end

    it 'should be able to remove students from the course' do
      visit "/courses/#{Course.first.slug}/students"

      click_button 'Enrollment'
      page.first('button.border.plus').click
      page.driver.browser.switch_to.alert.accept
      sleep 1
      expect(page).not_to have_content 'Student A'
    end

    it 'should be able to notify users with overdue training' do
      visit "/courses/#{Course.first.slug}/students"

      sleep 1
      # Notify users with overdue training
      page.first('button.notify_overdue').click
      page.driver.browser.switch_to.alert.accept
      sleep 1
    end

    it 'should be able to view their own deleted course' do
      Course.first.update_attributes(listed: false)
      visit "/courses/#{Course.first.slug}"
      expect(page).to have_content 'My Active Course'
    end

    it 'should not be able to view other deleted courses' do
      # Allow routing error to resolve to 404 page
      method = Rails.application.method(:env_config)
      expect(Rails.application).to receive(:env_config).with(no_args) do
        method.call.merge(
          'action_dispatch.show_exceptions' => true,
          'action_dispatch.show_detailed_exceptions' => false
        )
      end

      Course.first.update_attributes(listed: false)
      CoursesUsers.find(1).destroy
      visit "/courses/#{Course.first.slug}"
      expect(page).to have_content 'Page not found'
    end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
