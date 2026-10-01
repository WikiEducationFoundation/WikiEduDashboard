# frozen_string_literal: true

require 'rails_helper'

describe 'View as student', type: :feature, js: true do
  let(:course) { create(:course) }
  # A recent wiki token skips the course page's OAuth credentials check.
  let(:instructor) { create(:user, username: 'Prof', wiki_token: 'token') }
  let(:student) { create(:user, username: 'Student') }
  let(:assigned) { Assignment::Roles::ASSIGNED_ROLE }

  before do
    ActionController::Base.allow_forgery_protection = true
    stub_info_query # for the query that checks whether an article exists

    create(:courses_user, course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:courses_user, course:, user: student, real_name: 'Sam Student',
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:assignment, course:, article_title: 'Border_Collie', user: nil, role: assigned,
                        flags: { available_article: true })
    create(:assignment, course:, article_title: 'Poodle', user: student, role: assigned,
                        flags: { available_article: false })
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  context 'as an instructor' do
    before { login_as(instructor) }

    it 'shows the course as a student sees it until switched off' do
      visit "/courses/#{course.slug}"
      expect(page).to have_button 'Delete course'
      expect(page).not_to have_button 'Leave course'

      # It's switched on from the Actions panel, then moves into the course nav.
      within('.module.actions') { click_button 'View as student' }
      expect(page).to have_button 'Leave course'
      expect(page).not_to have_button 'Delete course'
      expect(page).to have_css 'nav [role="switch"][aria-checked="true"]', text: 'View as student'
      within('.module.actions') { expect(page).not_to have_button 'View as student' }

      # Students don't have the Assignments tab.
      visit "/courses/#{course.slug}/assignments"
      expect(page).to have_button 'Leave course'
      expect(page).to have_current_path "/courses/#{course.slug}"

      # It stays on across tabs and reloads, and can be switched off from any tab.
      visit "/courses/#{course.slug}/students"
      expect(page).to have_css 'nav [role="switch"][aria-checked="true"]', text: 'View as student'
      expect(page).to have_css 'tr.students .name', text: 'Student'
      expect(page).not_to have_content 'Sam Student'

      click_button 'View as student'
      expect(page).to have_content 'Sam Student'
      expect(page).not_to have_button 'View as student'
    end

    it 'keeps keyboard focus with the switch as it moves' do
      visit "/courses/#{course.slug}"
      find('.module.actions [role="switch"]').send_keys(:enter)
      expect(page).to have_css 'nav [role="switch"][aria-checked="true"]:focus'

      # Off on the Home tab: back to the switch in the Actions panel.
      find('nav [role="switch"]').send_keys(:enter)
      expect(page).to have_css '.module.actions [role="switch"][aria-checked="false"]:focus'

      # Off on a tab without the Actions panel: the current tab's link.
      find('.module.actions [role="switch"]').send_keys(:enter)
      find('#students-link a').click
      find('nav [role="switch"]').send_keys(:enter)
      expect(page).to have_css '#students-link a.active:focus'
      expect(page).not_to have_css '[role="switch"]'
    end

    it 'blocks a change that a student could make' do
      visit "/courses/#{course.slug}"
      click_button 'View as student'
      click_button 'Leave course'
      click_button 'OK'

      expect(page).to have_content I18n.t('courses.student_view_action_blocked')
      expect(CoursesUsers.exists?(course:, user: instructor)).to be true
    end

    it 'lets the instructor choose an article and one to review' do
      visit "/courses/#{course.slug}"
      click_button 'View as student'

      # Reviewing first: stub_info_query gives every article the same id, so
      # after choosing Border Collie, Poodle would count as already assigned.
      click_button 'Review an article'
      click_button 'Review'
      click_button 'OK'
      expect(page).to have_content "Articles I'm peer reviewing"

      click_button 'Assign myself an article'
      click_button 'Select'
      click_button 'OK'
      expect(page).to have_content "Articles I'm updating"

      expect(instructor.assignments.count).to eq(2)
    end
  end

  it 'is not offered on courses outside the Wikipedia Student Program' do
    editathon = create(:editathon, slug: 'School/Editathon_(2026)')
    create(:courses_user, course: editathon, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as(instructor)
    visit "/courses/#{editathon.slug}"
    expect(page).to have_content editathon.title
    expect(page).not_to have_button 'View as student'
  end

  it 'is not offered to admins who are not instructors of the course' do
    login_as(create(:admin, wiki_token: 'token'))
    visit "/courses/#{course.slug}"
    expect(page).to have_button 'Delete course'
    expect(page).not_to have_button 'View as student'
  end
end
