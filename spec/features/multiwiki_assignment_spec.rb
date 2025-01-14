# frozen_string_literal: true

require 'rails_helper'

describe 'multiwiki assignments', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course, submitted: true) }
  let(:user) { create(:user) }
  let(:wikisource) { Wiki.get_or_create(language: 'es', project: 'wikisource') }

  before do
    stub_wiki_validation
    page.current_window.resize_to(1920, 1080)

    allow(Features).to receive(:disable_wiki_output?).and_return(true)
    login_as(admin)
    course.campaigns << Campaign.last
    course.wikis << wikisource
    create(:courses_user, course_id: course.id, user_id: user.id,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  it 'creates a valid assignment from a wiki URL' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      button = first('.assign-button')
      expect(button).to have_content 'Assign/remove an article'
      button.click

      within('#users') do
        first('textarea').set(
          'https://ta.wiktionary.org/wiki/%E0%AE%86%E0%AE%99%E0%AF%8D%E0%AE%95%E0%AE%BF%E0%AE%B2%E0%AE%AE%E0%AF%8D',
          rapid: false
        )
      end
      click_button 'Assign'
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      within('#users') do
        expect(page).to have_content 'ஆங்கிலம்'
        link = first('.assignment-links a')
        expect(link[:href]).to include('ta.wiktionary')
      end
    end
  end

  it 'creates valid assignments from multiple article titles' do
    pending 'Fails in CI caused by Assign all button not found'

    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      button = first('.assign-button')
      expect(button).to have_content 'Assign/remove an article'
      button.click

      within('#users') do
        first('textarea').set(
          "Terre\nhttps://fr.wikipedia.org/wiki/Anglais"
        )
      end
      click_button 'Assign all'

      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      expect(page).to have_content 'Terre'
      expect(page).to have_content 'Anglais'

      expect(page).to have_css('a[href*="https://fr.wikipedia.org"]', text: 'Article', count: 2)

      expect(page).to have_css('a[href="https://fr.wikipedia.org/wiki/Anglais"]')
      expect(page).to have_css('a[href="https://fr.wikipedia.org/wiki/Terre"]')
    end

    pass_pending_spec
  end

  it 'creates a valid assignment from an article and a project and language from tracked Wikis' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      button = first('.assign-button')
      expect(button).to have_content 'Assign/remove an article'
      button.click

      within('#users') do
        find('textarea', visible: true).set('No le des prisa, dolor')
        click_link 'Change'
        find('div.wiki-select').click
        within('.wiki-select') do
          find('input').send_keys('es.wikisource', :enter)
        end
      end

      click_button 'Assign'

      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      within('#users') do
        expect(page).to have_content 'No le des prisa'
        link = first('.assignment-links a')
        expect(link[:href]).to include('es.wikisource')
      end
    end
  end

  it 'will create a valid assignment for multilingual wikisource projects' do
    pending 'Fails in CI caused by Heyder Cansa content not found'

    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      button = first('.assign-button')
      expect(button).to have_content 'Assign/remove an article'
      button.click
      within('#users') do
        first('textarea').set('https://wikisource.org/wiki/Heyder_Cansa')
      end
      click_button 'Assign'
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      within('#users') do
        expect(page).to have_content 'Heyder Cansa'
        link = first('.assignment-links a')
        expect(link[:href]).to include('wikisource')
      end
    end

    pass_pending_spec
  end

  it 'will create a valid assignment for multilingual wikimedia incubator projects' do
    pending 'Fails in CI caused by Wp/kiu/Hey content not found'

    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      button = first('.assign-button')
      expect(button).to have_content 'Assign/remove an article'
      button.click
      within('#users') do
        first('textarea').set('https://incubator.wikimedia.org/wiki/Wp/kiu/Heyder_Cansa')
      end
      click_button 'Assign'
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      within('#users') do
        expect(page).to have_content 'Wp/kiu/Hey'
        link = first('.assignment-links a')
        expect(link[:href]).to include('incubator.wikimedia')
      end
    end

    pass_pending_spec
  end
end
