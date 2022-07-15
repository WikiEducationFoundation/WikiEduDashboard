# frozen_string_literal: true

require 'rails_helper'

describe 'campaigns page', type: :feature, js: true do
  let(:user) { create(:user) }

  context 'hiding campaign creation' do
    it 'does not show the create button if the feature flag is off' do
      allow(Features).to receive(:open_course_creation?).and_return(false)
      login_as(user, scope: :user)
      visit '/campaigns'
      expect(page).to have_no_css('.create-campaign-button')
    end

    it 'does not show the create button if the user is logged out' do
      allow(Features).to receive(:open_course_creation?).and_return(false)
      visit '/campaigns'
      expect(page).to have_no_css('.create-campaign-button')
    end
  end

  describe 'search functionality' do
    before do
      @spring2016 = create(:campaign, id: 10001,
        title: 'My awesome Spring 2016 campaign',
        slug: 'spring2016',
        description: 'This is the best campaign')
      @spring2015 = create(:campaign, id: 12221,
        title: 'another spring campaign',
        slug: 'spring2015',
        description: 'This campaign could be better')
    end

    context 'campaigns list' do
      it 'lists the campaigns' do
        visit '/campaigns'
        expect(page).to have_content(@spring2016.title)
        expect(page).to have_content(@spring2015.title)
      end

      it 'renders the search results' do
        visit '/campaigns?search=some'
        # Should return only one campaign which matches the search criteria
        expect(page).to have_content(@spring2016.title)
        expect(page).not_to have_content(@spring2015.title)
      end

      it 'renders the "No results found"' do
        visit '/campaigns?search=xyz'
        expect(page).to have_content('No results found')
      end
    end
  end

  context 'campaign create modal' do
    before do
      allow(Features).to receive(:open_course_creation?).and_return(true)
      login_as(user, scope: :user)
      visit '/campaigns'
    end

    it 'appears when you click on the create button' do
      find('.create-campaign-button', visible: true)
      find('.wizard__panel', visible: false)
      find('.create-campaign-button').click
      find('.wizard__panel', visible: true)
    end

    it 'disappears when you click on cancel' do
      find('.create-campaign-button').click
      find('.wizard__panel', visible: true)
      find('.wizard__form .button__cancel').click
      find('.wizard__panel', visible: false)
    end

    it 'show errors if the created campaign is invalid with the modal is open' do
      find('.create-campaign-button').click
      fill_in('campaign_title', with: 'My Campaign Test')
      find('#use_dates').click
      fill_in('campaign_start', with: '2016-01-10'.to_date) # end date not supplied
      find('.wizard__form .button__submit').click
      find('.wizard__panel', visible: true)
      expect(page).to have_content(I18n.t('error.invalid_date', key: 'End'))
    end

    it 'creates a campaign with the given values when submitted' do
      title = 'My Campaign Test'
      description = 'My description'
      find('.create-campaign-button').click
      fill_in('campaign_title', with: title)
      fill_in('campaign_description', with: description)
      find('#use_dates').click
      fill_in('campaign_start', with: '2016-01-10'.to_date)
      fill_in('campaign_end', with: '2016-02-10'.to_date)
      find('.wizard__form .button__submit').click
      expect(Campaign.last.title).to eq(title)
      expect(Campaign.last.description).to eq(description)
      expect(Campaign.last.start).to eq(Time.zone.parse('2016-1-10 00:00:00'))
      expect(Campaign.last.end).to eq(Time.zone.parse('2016-02-10 23:59:59'))
    end

    it 'can be reached from the explore page' do
      visit '/explore'
      click_link 'Create a New Campaign'
      find('.wizard__panel', visible: true)
    end
  end
end
