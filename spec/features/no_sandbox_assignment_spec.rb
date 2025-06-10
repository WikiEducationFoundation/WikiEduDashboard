# frozen_string_literal: true

require 'rails_helper'

describe 'Assignments for No Sandbox courses', type: :feature, js: true, focus: true do
  let(:student) { create(:user) }
  let(:classmate) { create(:user, username: 'Classmate') }
  let(:no_sandboxes_flag) { { no_sandboxes: true } }
  let(:course) { create(:course, flags: no_sandboxes_flag) }

  before do
    ActionController::Base.allow_forgery_protection = true
    stub_info_query # for the query that checks whether an article exists

    create(:courses_user, user: student, course:)
    login_as(student)
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  it 'guide student through the Progress Tracker with no-sandbox steps' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'My Articles'

    click_button 'Assign myself an article'
    within('#assignment-input') { find('input', match: :first).set('Terrarium') }
    click_button 'Assign'
    click_button 'Done'
    find('.progress-tracker').click
    expect(find(:css, '.step.active')).to have_content 'Complete your bibliography'
    expect(page).to have_content 'Outline your changes'
    expect(page).to have_content 'Make your edits'
    within(:css, '.step.active') do
      click_button 'Mark Complete'
    end

    expect(find(:css, '.step.active')).to have_content 'Outline your changes'
    within(:css, '.step.active') do
      click_button 'Mark Complete'
    end

    expect(find(:css, '.step.active')).to have_content 'Make your edits'

  end
end
