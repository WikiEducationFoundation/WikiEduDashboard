# frozen_string_literal: true

require 'rails_helper'

describe 'Manage course flags admin page', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course) }

  describe 'as an admin' do
    before { login_as(admin) }
    after { logout }

    it 'loads the index search page' do
      visit '/course_flags'
      expect(page).to have_content 'Manage course flags'
      expect(page).to have_field 'course_id'
    end

    it 'shows current flag values for a valid course' do
      visit "/course_flags/show?course_id=#{course.id}"
      expect(page).to have_content course.slug
      expect(page).to have_content 'use_acuwt'
      expect(page).to have_content 'very_long_update'
      expect(page).to have_content 'debug_updates'
      expect(page).to have_content 'needs_update'
    end

    it 'updates flags and redirects with a notice' do
      visit "/course_flags/show?course_id=#{course.id}"
      select 'true', from: 'use_acuwt'
      select 'true', from: 'very_long_update'
      select 'true', from: 'debug_updates'
      select 'true', from: 'needs_update'
      click_button 'Update flags'
      expect(page).to have_content "Flags updated for course #{course.slug}"
      course.reload
      expect(course.flags[:use_acuwt]).to eq(true)
      expect(course.flags[:very_long_update]).to eq(true)
      expect(course.flags[:debug_updates]).to eq(true)
      expect(course.needs_update).to eq(true)
    end

    it 'redirects to index with an error when course is not found' do
      visit '/course_flags/show?course_id=0'
      expect(page).to have_content 'Manage course flags'
      expect(page).to have_content 'Course not found'
    end
  end

  describe 'as a non-admin' do
    before { login_as(create(:user)) }
    after { logout }

    it 'shows an unauthorized error' do
      visit '/course_flags'
      expect(page).to have_content 'Only administrators may do that.'
    end
  end

  describe 'when not signed in' do
    it 'shows a sign-in prompt' do
      visit '/course_flags'
      expect(page).to have_content 'Please sign in.'
    end
  end
end
