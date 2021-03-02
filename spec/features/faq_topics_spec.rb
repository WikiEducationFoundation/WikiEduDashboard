# frozen_string_literal: true

require 'rails_helper'

describe 'FAQ topics', type: :feature, js: true do
  let!(:faq) { create(:faq, title: 'How does this work?', content: 'It works.') }
  let(:admin) { create(:admin) }

  before { login_as admin }

  it 'lets an admin create, update and delete topics' do
    visit '/faq_topics'

    # Create an FAQ Topic
    click_link 'New Topic'
    fill_in 'slug', with: 'cool_new_topic'
    fill_in 'name', with: 'Topical Name'
    fill_in 'faqs', with: faq.id
    click_button 'Create FAQ Topic'
    expect(page).to have_content('Topical Name')
    expect(page).to have_content(faq.title)

    # Edit the topic
    click_link 'edit'
    fill_in 'name', with: 'Updated name'
    fill_in 'faqs', with: '1,2,3,4'
    click_button 'Update FAQ Topic'
    expect(page).to have_content('Updated name')

    # Delete the topic
    click_link 'edit'
    accept_confirm do
      click_button 'delete'
    end
    expect(page).to have_current_path('/faq_topics')
    expect(page).not_to have_content('Updated name')
  end
end
