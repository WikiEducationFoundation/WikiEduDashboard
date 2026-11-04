# frozen_string_literal: true

require 'rails_helper'

describe 'applying to a Scholars & Scientists course', type: :feature, js: true do
  let(:course) do
    create(:fellows_cohort, title: 'Elections workshop', end: 2.months.from_now,
                            slug: 'Wiki_Education/Elections_workshop_(2027)')
  end
  let(:apply_path) { "/courses/#{course.slug}/apply" }
  let(:user) { create(:user, onboarded: true) }
  let(:question_group) { create(:question_group, name: 'Base') }
  let!(:pronouns) do
    create(:q_radio, question_group:, question_text: 'What are your pronouns?',
                     answer_options: "She/her\r\nHe/him\r\nSomething else")
  end
  let!(:own_pronouns) do
    create(:q_short, question_group:, question_text: 'Please share your pronouns',
                     conditionals: "#{pronouns.id}|=|Something_else|multi")
  end

  before do
    CourseApplicationForm.create!(course:, open: true, intro: 'A six-week workshop.',
                                  question_group_ids: [question_group.id])
  end

  it 'asks a logged-out visitor to log in or sign up, on the course page' do
    visit apply_path
    within('.apply-card') do
      expect(page).to have_content(I18n.t('course_applications.accepting'))
      expect(page).to have_content(I18n.t('course_applications.account_needed'))
      expect(page).to have_content(I18n.t('application.log_in_extended'))
      expect(page).to have_button(I18n.t('application.sign_up_extended'))
      expect(page).to have_no_link(I18n.t('course_applications.apply'))
    end
  end

  it 'tells a logged-out visitor when the form is closed, without a log-in prompt' do
    course.course_application_form.update!(open: false)
    visit apply_path
    within('.apply-card') do
      expect(page).to have_content(I18n.t('course_applications.closed'))
      expect(page).to have_no_content(I18n.t('application.log_in_extended'))
    end
  end

  context 'when logged in' do
    before do
      login_as(user)
      visit apply_path
      within('.apply-card') do
        expect(page).to have_content('A six-week workshop.')
        click_link I18n.t('course_applications.apply')
      end
    end

    it 'shows a conditional question only while its condition is met' do
      expect(page).to have_content('What are your pronouns?')
      expect(page).to have_no_content('Please share your pronouns')

      within("#question_#{pronouns.id}") { choose 'Something else' }
      expect(page).to have_content('Please share your pronouns')

      within("#question_#{pronouns.id}") { choose 'She/her' }
      expect(page).to have_no_content('Please share your pronouns')
    end

    it 'submits the answers and returns to the card, which confirms it' do
      fill_in_built_in_application_questions
      within("#question_#{pronouns.id}") { choose 'Something else' }
      fill_in "answer_#{own_pronouns.id}", with: 'xe/xem'
      click_button 'Submit application'

      within('.apply-card') do
        expect(page).to have_content(I18n.t('course_applications.submitted'))
      end
      application = CourseApplication.find_by(course:, user:)
      expect(Rapidfire::Answer.find_by(question: own_pronouns).answer_text).to eq('xe/xem')
      # The built-in questions' group and the course's own.
      expect(application.answer_groups.count).to eq(2)
    end
  end

  describe 'grouped questions' do
    let(:scale) { "Disagree\r\nNeutral\r\nAgree" }
    let(:rules) do
      { presence: '1', grouped: '1', grouped_question: 'Motivations', minimum: '', maximum: '' }
    end
    let!(:statements) do
      ['Small inaccuracies bother me', 'I enjoy learning new skills'].map do |text|
        create(:q_radio, question_group:, question_text: text, answer_options: scale,
                         validation_rules: rules)
      end
    end

    it 'passes an accessibility check' do
      login_as(user)
      visit "#{apply_path}/form"
      expect(page).to have_css('.course-application__matrix')
      expect(page).to be_axe_clean.within('.course-application')
    end

    it 'shows them as one table and saves each row' do
      login_as(user)
      visit "#{apply_path}/form"
      within('.course-application__matrix') do
        expect(page).to have_content('Motivations')
        expect(page).to have_css('tbody tr', count: 2)
        find("#answer_#{statements.first.id}_2").click
        find("#answer_#{statements.last.id}_0").click
      end
      within("#question_#{pronouns.id}") { choose 'She/her' }
      fill_in_built_in_application_questions
      click_button 'Submit application'

      within('.apply-card') do
        expect(page).to have_content(I18n.t('course_applications.submitted'))
      end
      expect(Rapidfire::Answer.find_by(question: statements.first).answer_text).to eq('Agree')
      expect(Rapidfire::Answer.find_by(question: statements.last).answer_text).to eq('Disagree')
    end
  end
end
