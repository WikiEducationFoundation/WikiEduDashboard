require 'rails_helper'

describe 'Surveys', type: :feature, js: true do
  include Rapidfire::QuestionSpecHelper
  include Rapidfire::AnswerSpecHelper

  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
    page.current_window.resize_to(1920, 1080)
  end

  before :each do
    user = create(:admin,
                  id: 200,
                  wiki_token: 'foo',
                  wiki_secret: 'bar')
    login_as(user, scope: :user)
  end

  describe 'The Survey index' do
    before :each do
      visit '/surveys'
    end

    it 'Lists all surveys and allows an admin to create a new one.' do
      click_link('New Survey')
      expect(page.find("h1")).to have_content("New Survey")
      fill_in('survey[name]', :with => 'My New Awesome Survey')
      click_button('Create Survey')
      expect(page.find(".course-list__row")).to have_content("My New Awesome Survey")
      click_link('Delete')
      prompt = page.driver.browser.switch_to.alert
      prompt.accept
      expect(page).not_to have_select('.course-list__row')
    end

    it 'Has a link to Question Groups' do
      click_link('Question Groups')
      expect(page).to have_content("Question Groups")
    end
  end

  describe 'Editing a Survey' do
    
    # let!(:question_group)  { FactoryGirl.create(:question_group, name: "Survey Section 1") }
    # let!(:survey)  { create(:survey, name: "Dumb Survey", :rapidfire_question_groups => [question_group]) }
 
    # before :each do
    #   create_questions(question_group)
    #   @intro_text = "My introduction"
    #   visit '/surveys'
    #   expect(page).to have_content(survey.name)
    #   within('.course-list__row') do
    #     find(:link, 'Edit').click
    #   end
    #   expect(page).to have_content("Editing #{survey.name}")
    # end

    # it 'An admin can the survey introduction' do
    #   fill_in_trix_editor("trix-toolbar-1", @intro_text)
    #   click_button "Update Survey";
    #   within('.course-list__row') do
    #     click_link("View Survey"); sleep 2;
    #     expect(page.find(".survey__title")).to have_content(survey.name)
    #     expect(page.find("[data-survey-block='0']")).to have_content(@intro_text)
    #   end
    # end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end