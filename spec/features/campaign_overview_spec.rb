# frozen_string_literal: true
require 'rails_helper'

describe 'campaign overview page', type: :feature, js: true do
  let(:slug)  { 'spring_2016' }
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:campaign) do
    create(:campaign,
           id: 10001,
           title: 'My awesome Spring 2016 campaign',
           slug: slug,
           description: 'This is the best campaign')
  end

  before do
    Capybara.current_driver = :poltergeist
  end

  context 'as an user' do
    it 'should not show the edit buttons' do
      login_as(user, scope: user)
      visit "/campaigns/#{campaign.slug}"
      expect(page).to have_no_css('.campaign-description .rails_editable-edit')
    end
  end

  context 'as an admin' do
    before do
      login_as(admin, scope: :user)
      visit "/campaigns/#{campaign.slug}"
    end

    it 'shows the description input field when in edit mode' do
      find('.campaign-description .rails_editable-edit').click
      find('#campaign_description', visible: true)
    end

    it 'updates the campaign when you click save' do
      new_description = 'This is my new description'
      find('.campaign-description .rails_editable-edit').click
      fill_in('campaign_description', with: new_description)
      find('.campaign-description .rails_editable-save').click
      expect(page).to have_content('Campaign updated')
      expect(campaign.reload.description).to eq(new_description)
    end
  end
end
