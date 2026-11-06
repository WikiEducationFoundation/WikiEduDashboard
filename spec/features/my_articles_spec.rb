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

  it 'does not show the assign, review and find buttons when the course metadata is locked' do
    course.update(flags: { finalized: true })
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'My Articles'

    within '.my-articles-header' do
      expect(page).not_to have_css('.assign-button')
    end
  end

  it 'shows the remove button on an assigned article' do
    create(:assignment, course:, article_title: 'Shiba_Inu', user: student, role: ASSIGNED,
flags: { available_article: false })
    visit "/courses/#{course.slug}"
    expect(page).to have_content "Articles I'm updating"

    expect(page).to have_button 'Remove'
  end

  it 'does not show the remove button on an assigned article when the course metadata is locked' do
    create(:assignment, course:, article_title: 'Shiba_Inu', user: student, role: ASSIGNED,
flags: { available_article: false })
    course.update(flags: { finalized: true })
    visit "/courses/#{course.slug}"
    expect(page).to have_content "Articles I'm updating"

    expect(page).not_to have_button 'Remove'
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

  context 'when a classmate is drafting a new article' do
    let(:sandbox_url) { 'https://en.wikipedia.org/wiki/User:Classmate/The_Teaching_of_Love' }

    before do
      create(:assignment, course:, article_title: 'The_Teaching_of_Love', article_id: nil,
                          user: classmate, role: ASSIGNED)
    end

    def enter_review(title)
      visit "/courses/#{course.slug}"
      click_button 'Review an article'
      within('#assignment-input') { find('input', match: :first).set(title) }
      click_button 'Assign'
    end

    it "links the review option to the classmate's sandbox draft" do
      visit "/courses/#{course.slug}"
      click_button 'Review an article'
      expect(page).to have_link('The Teaching of Love', href: sandbox_url)
      expect(page).to have_content I18n.t('assignments.review_classmate_draft',
                                          username: 'Classmate')
    end

    it "adds a review of the classmate's article from their sandbox URL" do
      enter_review(sandbox_url)

      expect(page).to have_content "Articles I'm peer reviewing"
      review = student.assignments.find_by(role: REVIEWING)
      expect(review.article_title).to eq('The_Teaching_of_Love')
      expect(review.sandbox_url).to eq(sandbox_url)
    end

    it "shows an error for a User page that isn't a classmate's draft" do
      enter_review('User:Classmate/sandbox')

      expect(page).to have_content I18n.t('assignments.review_sandbox_not_found',
                                          title: 'User:Classmate/sandbox')
      expect(student.assignments.where(role: REVIEWING).count).to eq(0)
    end
  end
end
