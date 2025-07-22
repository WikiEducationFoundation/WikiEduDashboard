# frozen_string_literal: true

require 'rails_helper'

describe 'Online Volunteer users', type: :feature, js: true do
  let(:user) { create(:user) }
  let(:course) do
    create(:basic_course, end: 1.day.from_now,
                          flags: { online_volunteers_enabled: true, wiki_edits_enabled: false })
  end

  before do
    include type: :feature
    include Devise::TestHelpers

    login_as(user, scope: :user)
    allow(Features).to receive(:wiki_ed?).and_return(false)
    allow(Features).to receive(:disable_wiki_output?).and_return(true)

    course.campaigns << Campaign.first
  end

  describe 'on a course page' do
    it 'can join without a passcode' do
      visit "/courses/#{course.slug}"

      click_button 'Volunteer to help'
      click_button 'OK'
      expect(page).not_to have_content('Volunteer to help')
      expect(course.users).to include(user)
    end
  end
end
