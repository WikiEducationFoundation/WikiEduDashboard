# frozen_string_literal: true

require 'rails_helper'

describe 'applying to a Scholars & Scientists course', type: :feature, js: true do
  let(:course) do
    create(:fellows_cohort, title: 'Elections workshop', end: 2.months.from_now,
                            slug: 'Wiki_Education/Elections_workshop_(2027)')
  end
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
    CourseApplicationForm.create!(course:, open: true, question_group_ids: [question_group.id])
    login_as(user)
    visit "/courses/#{course.slug}/apply"
  end

  it 'shows a conditional question only while its condition is met' do
    expect(page).to have_content('What are your pronouns?')
    expect(page).to have_no_content('Please share your pronouns')

    choose 'Something else'
    expect(page).to have_content('Please share your pronouns')

    choose 'She/her'
    expect(page).to have_no_content('Please share your pronouns')
  end

  it 'submits the answers to the questions that were shown' do
    choose 'Something else'
    fill_in "answer_#{own_pronouns.id}", with: 'xe/xem'
    click_button 'Submit application'

    expect(page).to have_content(I18n.t('course_applications.submitted'))
    application = CourseApplication.find_by(course:, user:)
    expect(Rapidfire::Answer.find_by(question: own_pronouns).answer_text).to eq('xe/xem')
    expect(application.answer_groups.count).to eq(1)
  end
end
