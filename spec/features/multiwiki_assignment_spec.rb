# frozen_string_literal: true

require 'rails_helper'

describe 'multiwiki assignments', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course, submitted: true) }
  let(:user) { create(:user) }

  before do
    page.current_window.resize_to(1920, 1080)

    allow(Features).to receive(:disable_wiki_output?).and_return(true)
    login_as(admin)
    course.campaigns << Campaign.last
    create(:courses_user, course_id: course.id, user_id: user.id,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  it 'creates a valid assignment from a wiki URL' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students"
      click_button 'Assign Articles'
      click_button 'Assign an article'
      within('#users') do
        first('input').set('https://ta.wiktionary.org/wiki/%E0%AE%86%E0%AE%99%E0%AF%8D%E0%AE%95%E0%AE%BF%E0%AE%B2%E0%AE%AE%E0%AF%8D')
      end
      click_button 'Assign'
      click_button 'OK'
      visit "/courses/#{course.slug}/students"

      within('#users') do
        expect(page).to have_content 'ta:wiktionary:ஆங்கிலம்'
      end
    end
  end

  it 'creates a valid assignment from an article and an alternative project and language' do
    pending 'This sometimes fails on travis.'

    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students"
      click_button 'Assign Articles'
      click_button 'Assign an article'

      within('#users') do
        find('input', visible: true).set('No le des prisa, dolor')
        click_link 'Change'
        find('div.language-select').click
        within('.language-select') do
          find('div.Select--single div.Select-value').send_keys('es', :enter)
        end

        find('div.project-select').click
        within('.project-select') do
          find('div.Select--single div.Select-value').send_keys('wikisource', :enter)
        end
      end

      click_button 'Assign'
      click_button 'OK'

      visit "/courses/#{course.slug}/students"

      within('#users') do
        expect(page).to have_content 'es:wikisource:No le des prisa, dolor'
      end
    end

    puts 'PASSED'
    raise 'this test passed — this time'
  end

  it 'will create a valid assignment for multilingual wikisource projects' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students"
      click_button 'Assign Articles'
      click_button 'Assign an article'
      within('#users') do
        first('input').set('https://wikisource.org/wiki/Heyder_Cansa')
      end
      click_button 'Assign'
      click_button 'OK'
      visit "/courses/#{course.slug}/students"

      within('#users') do
        expect(page).to have_content 'wikisource:Heyder Cansa'
      end
    end
  end

  it 'will create a valid assignment for multilingual wikimedia incubator projects' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students"
      click_button 'Assign Articles'
      click_button 'Assign an article'
      within('#users') do
        first('input').set('https://incubator.wikimedia.org/wiki/Wp/kiu/Heyder_Cansa')
      end
      click_button 'Assign'
      click_button 'OK'
      visit "/courses/#{course.slug}/students"

      within('#users') do
        expect(page).to have_content 'incubator:wikimedia:Wp/kiu/Heyder Cansa'
      end
    end
  end
end
