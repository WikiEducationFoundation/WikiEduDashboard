# frozen_string_literal: true
require 'rails_helper'

describe 'campaigns page', type: :feature, js: true do
  let(:user)  { create(:user) }

  context 'when feature flag is off' do
    it 'should not show the create button' do
      allow(Features).to receive(:open_course_creation?).and_return(false)
      login_as(user, scope: user)
      visit '/campaigns'
      find('.create-campaign-button', visible: false)
    end
  end

  context 'campaigns list' do
    it 'should list the campaigns' do
      campaign = create(:campaign, id: 10001,
                                   title: 'My awesome Spring 2016 campaign',
                                   slug: 'spring_2016',
                                   description: 'This is the best campaign')
      visit '/campaigns'
      within('.campaign-list') { expect(page).to have_content(campaign.title) }
    end
  end

  context 'campaign create modal' do
    before do
      login_as(user, scope: user)
      visit '/campaigns'
    end

    it 'should show the create campaign modal when you click on the create button' do
      find('.create-campaign-button', visible: true)
      find('.wizard__panel', visible: false)
      find('.create-campaign-button').click
      find('.wizard__panel', visible: true)
    end

    it 'should hide the create campaign modal when you click on cancel' do
      find('.create-campaign-button').click
      find('.wizard__panel', visible: true)
      find('.wizard__form .button__cancel').click
      find('.wizard__panel', visible: false)
    end

    it 'should show errors if the created campaign is invalid with the modal is open' do
      find('.create-campaign-button').click
      fill_in('campaign_title', with: 'My Campaign Test')
      fill_in('campaign_start', '2016-01-10') # end date not supplied
      find('.wizard__form .button__submit').click
      find('.wizard__panel', visible: true)
      expect(page).to have_content(I18n.t('error.invalid_date', key: 'End'))
    end
  end
end
