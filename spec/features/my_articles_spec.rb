# frozen_string_literal: true

require 'rails_helper'

ASSIGNED = Assignment::Roles::ASSIGNED_ROLE
REVIEWING = Assignment::Roles::REVIEWING_ROLE

describe 'My Articles', type: :feature, js: true do
  let(:student) { create(:user) }
  let(:classmate) { create(:user, username: 'Classmate') }
  let(:course) { create(:course) }

  before do
    stub_info_query # for the query that checks whether an article exists

    create(:courses_user, user: student, course: course)
    create(:assignment, course: course, article_title: 'Border_Collie', user: nil, role: ASSIGNED)
    create(:assignment, course: course, article_title: 'Poodle', user: classmate, role: ASSIGNED)
    login_as(student)
  end

  it 'lets a student choose an available article' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'My Articles'

    click_button 'Assign myself an article'
    click_button '+' # FIXME: clearer button label like "Select"
    click_button 'OK'

    # FIXME: better label that won't confuse people who created a new article,
    # like "Articles I will create"
    expect(page).to have_content "Articles I'm Improving"
    expect(student.assignments.where(role: ASSIGNED).count).to eq(1)
  end

  it 'lets a student choose a second article' do
    create(:assignment, course: course, article_title: 'Shiba_Inu', user: student, role: ASSIGNED)

    visit "/courses/#{course.slug}"
    expect(page).to have_content 'My Articles'
    expect(page).to have_content "Articles I'm Improving"

    # FIXME: This should not be the +/- label, it should still be 'Assign myself an article'
    click_button '+/-'
    click_button '+' # FIXME: clearer button label like "Select"
    click_button 'OK'

    # FIXME: better label that won't confuse people who created a new article,
    # like "Articles I will create"
    expect(page).to have_content 'Shiba Inu'
    expect(student.assignments.where(role: ASSIGNED).count).to eq(2)
  end

  it "lets a student choose a classmate's article to review" do
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'My Articles'

    click_button 'Review an article'
    click_button '+' # FIXME: clearer button label like "Review"
    click_button 'OK'
    # FIXME: update label to "Articles I'm peer reviewing"
    expect(page).to have_content "Articles I'm Reviewing"
    expect(student.assignments.where(role: REVIEWING).count).to eq(1)
  end
end
