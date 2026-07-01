# frozen_string_literal: true

require 'rails_helper'

describe 'Text area input that uses the rich text editor', type: :feature, js: true do
  let(:course) { create(:course, weekdays: '0101010') }
  let(:user) { create(:admin) }

  before do
    login_as user
    stub_oauth_edit
  end

  it 'lets a user input text and save it' do
    visit "/courses/#{course.slug}/timeline"
    click_button 'Add Week'
    click_button 'Add Block'
    find('.wysiwyg-editor__content').click
    find('.wysiwyg-editor__content').send_keys('Hello, my name is Sage')
    expect(page).to have_content('Hello, my name is Sage')
    click_button 'Save'
    expect(page).to have_content('Hello, my name is Sage')
  end
end
