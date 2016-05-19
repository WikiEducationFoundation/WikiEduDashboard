require 'rails_helper'

describe 'multiwiki assignments', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course, submitted: true) }
  let(:user) { create(:user) }

  before do
    Capybara.current_driver = :selenium
    page.current_window.resize_to(1920, 1080)

    allow(Features).to receive(:disable_wiki_output?).and_return(true)
    login_as(admin)
    course.cohorts << Cohort.last
    create(:courses_user, course_id: course.id, user_id: user.id,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  it 'creates a valid assignment from a wiki URL' do
    visit "/courses/#{course.slug}/students"
    click_button 'Assign Articles'
    click_button 'Assign an article'
    within('#users') do
      first('input').set('https://ta.wiktionary.org/wiki/%E0%AE%86%E0%AE%99%E0%AF%8D%E0%AE%95%E0%AE%BF%E0%AE%B2%E0%AE%AE%E0%AF%8D')
    end
    page.accept_confirm do
      click_button 'Assign'
    end
    visit "/courses/#{course.slug}/students"

    expect(page).to have_content 'ta:wiktionary:ஆங்கிலம்'
    expect(Assignment.last.wiki.language).to eq('ta')
    expect(Assignment.last.wiki.project).to eq('wiktionary')
  end
end
