# frozen_string_literal: true
require 'rails_helper'

describe 'campaign overview page', type: :feature, js: true do
  let(:slug)  { 'spring_2016' }
  let(:user)  { create(:user) }
  let(:campaign) do
    create(:campaign,
           id: 10001,
           title: 'My awesome Spring 2016 campaign',
           slug: slug,
           description: 'This is the best campaign')
  end

  context 'as an user' do
    it 'should not show the edit buttons' do
      login_as(user, scope: user)
      visit "/campaigns/#{campaign.slug}"
      expect(page).to have_no_css('.campaign-description .rails_editable-edit')
    end
  end

  context 'as a campaign organizer' do
    before do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      login_as(user, scope: :user)
      visit "/campaigns/#{campaign.slug}"
    end

    describe 'campaign description' do
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

    describe 'campaign details' do
      it 'shows add organizers button and title field when in edit mode' do
        find('.campaign-details .rails_editable-edit').click
        find('.campaign-details .button.plus', visible: true)
        find('#campaign_title', visible: true)
      end

      it 'updates the campaign when you click save' do
        new_title = 'My even more awesome campaign 2016'
        find('.campaign-details .rails_editable-edit').click
        fill_in('campaign_title', with: new_title)
        find('.campaign-details .rails_editable-save').click
        expect(page).to have_content('Campaign updated')
        expect(campaign.reload.title).to eq(new_title)
      end

      it 'shows an error if you try to add a nonexistent user as an organizer' do
        find('.campaign-details .rails_editable-edit').click
        find('.campaign-details .button.plus').click
        username = 'Nonexistent user'
        fill_in('username', with: username)
        find('.add-organizer-button').click
        expect(page).to have_content(I18n.t('courses.error.user_exists', username: username))
        expect(campaign.reload.organizers.collect(&:username)).not_to include(username)
      end

      context 'start and end dates' do
        it "hides the start and end dates unless the 'Use start and end dates' is checked" do
          find('.campaign-details .rails_editable-edit').click
          find('#campaign_start', visible: false)
          find('#use_dates').click
          find('#campaign_start', visible: true)
        end

        it 'shows an error for invalid dates' do
          find('.campaign-details .rails_editable-edit').click
          find('#use_dates').click
          fill_in('campaign_start', with: '2016-01-10')
          fill_in('campaign_end', with: 'Invalid date')
          find('.campaign-details .rails_editable-save').click
          expect(page).to have_content(I18n.t('error.invalid_date', key: 'End'))
          find('#campaign_end', visible: true) # field with the error should be visible
        end

        it "updates the date fields properly, and to nil if the 'Use start and end dates' become unchecked" do
          find('.campaign-details .rails_editable-edit').click
          find('#use_dates').click
          fill_in('campaign_start', with: '2016-01-10')
          fill_in('campaign_end', with: '2016-02-10')
          find('.campaign-details .rails_editable-save').click
          expect(campaign.reload.start).to eq(DateTime.civil(2016, 1, 10, 0, 0, 0))
          expect(campaign.end).to eq(DateTime.civil(2016, 2, 10, 23, 59, 59))
          find('.campaign-details .rails_editable-edit').click
          find('#use_dates').click # uncheck
          find('#campaign_start', visible: false)
          find('.campaign-details .rails_editable-save').click
          find('#campaign_start', visible: false)
          expect(campaign.reload.start).to be_nil
          expect(campaign.end).to be_nil
        end
      end
    end

    describe 'campaign deletion' do
      it 'deletes the campaign when you click on delete' do
        accept_prompt(with: campaign.title) do
          find('.campaign-delete .button').click
        end
        expect(page).to have_content('has been deleted')
        expect(Campaign.find_by_slug(campaign.slug)).to be_nil
      end

      it 'throws an error if you enter the wrong campaign title when trying to delete it' do
        wrong_title = 'Not the title of the campaign'
        accept_alert(with: /"#{wrong_title}"/) do
          accept_prompt(with: wrong_title) do
            find('.campaign-delete .button').click
          end
        end
      end
    end
  end
end
