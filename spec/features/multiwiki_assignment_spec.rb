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
        first('input').set(
          'https://ta.wiktionary.org/wiki/%E0%AE%86%E0%AE%99%E0%AF%8D%E0%AE%95%E0%AE%BF%E0%AE%B2%E0%AE%AE%E0%AF%8D',
          rapid: false
        )
      end
      click_button 'Assign'
      # Click done to ensure assignments are created and displayed
      find('.assign-button', text: 'Done').click
      within('#users') do
         expect(page).not_to have_selector('input')
      end

      first('.student-selection .student').click

      within('#users') do
        expect(page).to have_content 'ஆங்கிலம்'
        link = first('.assignment-links a')
        expect(link[:href]).to include('ta.wiktionary')
      end
    end
  end

  it 'creates a valid assignment from an article and a project and language from tracked Wikis' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      button = first('.assign-button')
      expect(button).to have_content 'Assign/remove an article'
      button.click

      within('#users') do
        find('input', visible: true).set('No le des prisa, dolor', rapid: false)
        click_link 'Change'
        find('div.wiki-select').click
        within('.wiki-select') do
          find('input').send_keys('es.wikisource', :enter)
        end
      end

      click_button 'Assign'

      find('.assign-button', text: 'Done').click
      within('#users') do
         expect(page).not_to have_selector('input')
      end

      first('.student-selection .student').click

      within('#users') do
        expect(page).to have_content 'No le des prisa'
        link = first('.assignment-links a')
        expect(link[:href]).to include('es.wikisource')
      end
    end
  end

  it 'create a valid assignment for a  wikisource mainspace article in a classroomProgramCourse' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click
      button = first('.assign-button')
      expect(button).to have_content 'Assign/remove an article'
      button.click
      within('#users') do
        first('input').set('https://en.wikisource.org/wiki/Alice%27s_Adventures_in_Wonderland',
        rapid: false)
      end

      click_button 'Assign'

      find('.assign-button', text: 'Done').click
      within('#users') do
         expect(page).not_to have_selector('input')
      end

      first('.student-selection .student').click

      within('#users') do
        expect(page).to have_content "Alice's Adventures in Wonderland"
        link = first('.assignment-links a')
        expect(link[:href]).to include('wikisource')
      end
    end
  end

  context 'will create a valid assignment for multilingual wikisource projects' do
    # Use BasicCourse so Wikisource assignments are allowed
    let(:basic_course)  {create(:basic_course, submitted: true)}
    let(:instructor)  { create(:instructor)}
    let(:student) { create(:user, username: 'StudentUser')}

    before do
      basic_course.campaigns << Campaign.last
      basic_course.wikis << Wiki.get_or_create(language: 'en', project: 'wikisource')
      create(:courses_user,
            course_id: basic_course.id,
            user_id: instructor.id,
            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      
      #Enroll Student into the Course
      create(:courses_user,
            course_id: basic_course.id,
            user_id: student.id,
            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    it "create assignment for wikisource project to a basic course" do
      VCR.use_cassette 'multiwiki_assignment' do

        visit "/courses/#{basic_course.slug}/students/articles"
  
        first('.student-selection .student').click
  
        button = first('.assign-button')
        expect(button).to have_content 'Assign/remove an article'
        button.click

        within('#users') do
          first('input').set('https://wikisource.org/wiki/Heyder_Cansa', rapid: false)
        end

        click_button 'Assign'

        find('.assign-button', text: 'Done').click
        within('#users') do
          expect(page).not_to have_selector('input')
        end

        first('.student-selection .student').click
  
        within('#users') do
          expect(page).to have_content "Heyder Cansa"
          link = first('.assignment-links a')
          expect(link[:href]).to include('wikisource')
        end
      end
    end
  end

  it 'will create a valid assignment for multilingual wikimedia incubator projects' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students/articles"
      first('.student-selection .student').click

      button = first('.assign-button')
      expect(button).to have_content 'Assign/remove an article'
      button.click
      within('#users') do
        first('input').set('https://incubator.wikimedia.org/wiki/Wp/kiu/Heyder_Cansa',
                           rapid: false)
      end

      click_button 'Assign'

      find('.assign-button', text: 'Done').click
      within('#users') do
        expect(page).not_to have_selector('input')
      end

      first('.student-selection .student').click

      within('#users') do
        expect(page).to have_content 'Wp/kiu/Hey'
        link = first('.assignment-links a')
        expect(link[:href]).to include('incubator.wikimedia')
      end
    end
  end
  it 'prevents assignment of non-mainspace articles' do
    VCR.use_cassette 'multiwiki_assignment' do
      visit "/courses/#{course.slug}/students/articles"
      find('.student-selection .student').click

      find('.assign-button', text: 'Assign/remove an article').click

      within('#users') do
        find('input').set('https://en.wikipedia.org/wiki/Category:1993_in_sports_in_Alberta',
         rapid: false)
      end

      click_button 'Assign'

      find('.assign-button', text: 'Done').click
      within('#users') do
        expect(page).not_to have_selector('input')
      end

      # Wait and assert the notification
      expect(page).to have_css('.notifications .notice')
      expect(page).to have_content('is not a mainspace article')

      find('.student-selection .student').click

      within('#users') do
        expect(page).to have_no_content('Category:1993 in sports in Alberta')
      end
    end
  end
end
