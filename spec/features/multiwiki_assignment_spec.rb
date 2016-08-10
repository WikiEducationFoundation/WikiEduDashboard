require 'rails_helper'

describe 'multiwiki assignments', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course, submitted: true) }
  let(:user) { create(:user) }

  before do
    Capybara.current_driver = :poltergeist
    page.current_window.resize_to(1920, 1080)

    allow(Features).to receive(:disable_wiki_output?).and_return(true)
    login_as(admin)
    course.cohorts << Cohort.last
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
      page.accept_confirm do
        click_button 'Assign'
      end
      visit "/courses/#{course.slug}/students"

      expect(page).to have_content 'ta:wiktionary:ஆங்கிலம்'
      expect(Assignment.last.wiki.language).to eq('ta')
      expect(Assignment.last.wiki.project).to eq('wiktionary')
      expect(Assignment.last.article.title).to eq('ஆங்கிலம்')
      expect(Assignment.last.article.wiki.language).to eq('ta')
      expect(Assignment.last.article.wiki.project).to eq('wiktionary')
    end
  end

  it 'creates a valid assignment from an article and an alternative project and language' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students"
      click_button 'Assign Articles'
      click_button 'Assign an article'

      within('#users') do
        first('input').set('Livre_de_cuisine')
        first(:link, 'Change').click
        first('.language-select').click
        first('.language-select .Select-input input').set('fr')
        first('.language-select .Select-option', text: 'fr').click
        first('.project-select').click
        first('.project-select .Select-input input').set('wikibooks')
        first('.project-select .Select-option', text: 'wikibooks').click
      end

      page.accept_confirm do
        click_button 'Assign'
      end

      visit "/courses/#{course.slug}/students"

      expect(page).to have_content 'fr:wikibooks:Livre de cuisine'
      expect(Assignment.last.wiki.language).to eq('fr')
      expect(Assignment.last.wiki.project).to eq('wikibooks')
      expect(Assignment.last.article.title).to eq('Livre_de_cuisine')
      expect(Assignment.last.article.wiki.language).to eq('fr')
      expect(Assignment.last.article.wiki.project).to eq('wikibooks')
    end
  end
end
