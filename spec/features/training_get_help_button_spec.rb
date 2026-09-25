# frozen_string_literal: true

require 'rails_helper'

describe 'training GetHelp button', type: :feature, js: true do
  let(:user) { create(:user) }
  let(:library_id) { 'students' }
  let(:module_id)  { TrainingModule.all.first.slug }
  let(:slide_id) { 'five-pillars' }
  let(:expert) { create(:user, username: 'Wiki Expert') }

  before do
    login_as user
    TrainingModule.load_all
    allow(Features).to receive(:enable_get_help_button?).and_return(true)
  end
  describe 'Course is Available' do
    before do
        course = create(:course)
        create(:courses_user, course_id: course.id, user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE)
        create(:courses_user, course_id: course.id, user: expert, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    end
    it 'shows contact staff options' do
        visit "/training/#{library_id}/#{module_id}/#{slide_id}"
        expect(page).to have_css('.training__slide-header')
        find('#get-help-button button').click
        expect(page).to have_selector('p.target-users')
    end
  end

  describe 'Course is not Available' do
    it 'shows no contact staff options' do
        visit "/training/#{library_id}/#{module_id}/#{slide_id}"
        expect(page).to have_css('.training__slide-header')
        find('#get-help-button button').click
        expect(page).not_to have_selector('p.target-users')
    end
  end
end
