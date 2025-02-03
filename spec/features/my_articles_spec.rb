# frozen_string_literal: true

require 'rails_helper'

ASSIGNED = Assignment::Roles::ASSIGNED_ROLE
REVIEWING = Assignment::Roles::REVIEWING_ROLE

describe 'My Articles', type: :feature, js: true do
  let(:student) { create(:user) }
  let(:classmate) { create(:user, username: 'Classmate') }
  let(:course) { create(:course) }

  before do
    ActionController::Base.allow_forgery_protection = true
    stub_info_query # for the query that checks whether an article exists

    create(:courses_user, user: student, course:)
    create(:assignment, course:, article_title: 'Border_Collie', user: nil, role: ASSIGNED,
flags: { available_article: true })
    create(:assignment, course:, article_title: 'Poodle', user: classmate, role: ASSIGNED,
flags: { available_article: false })
    login_as(student)
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  it 'lets a student choose an available article' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'My Articles'

    click_button 'Assign myself an article'
    click_button 'Select'
    click_button 'OK'

    expect(page).to have_content "Articles I'm updating"
    expect(student.assignments.where(role: ASSIGNED).count).to eq(1)
    expect(student.assignments.where(flags: { available_article: true }).count).to eq(1)
  end

  it 'lets a student choose a second article' do
    create(:assignment, course:, article_title: 'Shiba_Inu', user: student, role: ASSIGNED,
flags: { available_article: false })

    visit "/courses/#{course.slug}"
    expect(page).to have_content 'My Articles'
    expect(page).to have_content "Articles I'm updating"

    click_button 'Assign myself an article'
    click_button 'Select'
    click_button 'OK'

    expect(page).to have_content 'Shiba Inu'
    expect(student.assignments.where(role: ASSIGNED).count).to eq(2)
    expect(student.assignments.where(flags: { available_article: false }).count).to eq(1)
  end

  it "lets a student choose a classmate's article to review" do
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'My Articles'

    click_button 'Review an article'
    click_button 'Review'
    click_button 'OK'

    expect(page).to have_content "Articles I'm peer reviewing"
    expect(student.assignments.where(role: REVIEWING).count).to eq(1)
  end
end
