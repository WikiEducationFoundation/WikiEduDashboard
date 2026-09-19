require 'rails_helper'

describe 'Training GetHelp Button', type: :feature, js: true do
    let(:user) { create(:user) }
    let(:library_id) { 'students' }
    let(:module_id)  { TrainingModule.all.first.slug }
    let(:slide_id) { 'five-pillars' }
    let(:course) { create(:course) }
    let(:expert) { create(:user, username: 'Wiki Expert') }

    before do
        login_as user
        TrainingModule.load_all
        allow(Features).to receive(:enable_get_help_button?).and_return(true)
        create(:courses_user, course_id: course.id, user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE)
        create(:courses_user, course_id: course.id, user: expert, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    end
   
    it 'shows contact staff options for a course', js_error_expected: true do
        
        visit "/training/#{library_id}/#{module_id}/#{slide_id}"
        expect(page).to have_css('.training__slide-header')
        find('.training-btn').click
        expect(page).to have_selector('p.target-users')
    end

    it 'shows no contact staff options for no course', js_error_expected: true do
        visit "/training/#{library_id}/#{module_id}/#{slide_id}"
        expect(page).not_to have_selector('p.target-users')
    end
end