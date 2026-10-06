# frozen_string_literal: true

require 'rails_helper'

describe 'downloads icon in the nav', type: :feature, js: true do
  let(:user) { create(:user) }
  let(:campaign) { create(:campaign, title: 'Spring 2016 campaign', slug: 'spring_2016') }
  let(:csv_url) { '/system/analytics/spring_2016-students.csv' }

  before do
    campaign
    login_as(user)
  end

  it 'is hidden until there is a download to show' do
    visit '/campaigns'
    expect(page).to have_css('.campaign-export-button')
    expect(page).to have_no_css('.downloads-bell')
  end

  it 'keeps an in-progress export across a page load and picks its polling back up' do
    allow(ReportCsvWorker).to receive(:generate_csv) # the file stays ungenerated

    visit '/campaigns'
    find('tr', text: campaign.title).find('.campaign-export-button').click
    first('.campaign-export-modal button.button--block').click
    expect(page).to have_content(I18n.t('campaign.data_download_generating'))

    # The file finishes while the user is on another page load.
    allow(ReportCsvStore).to receive(:exists?).and_return(true)
    allow(ReportCsvStore).to receive(:url_for).and_return(csv_url)
    visit '/campaigns'

    find('.downloads-bell').click
    within('.pop--downloads') do
      expect(page).to have_content("#{campaign.title} — #{I18n.t('campaign.students_small')}")
      expect(page).to have_link(I18n.t('downloads.download'), href: csv_url)
    end
  end

  it 'confirms an export that is already generating when it is requested again' do
    allow(ReportCsvWorker).to receive(:generate_csv) # the file stays ungenerated

    visit '/campaigns'
    find('tr', text: campaign.title).find('.campaign-export-button').click
    first('.campaign-export-modal button.button--block').click
    expect(page).to have_content(I18n.t('campaign.data_download_generating'))

    # After a page load, the export's polling is resumed rather than started anew.
    visit '/campaigns'
    expect(page).to have_css('.downloads-bell')
    expect(page).to have_no_content(I18n.t('campaign.data_download_generating'))

    find('tr', text: campaign.title).find('.campaign-export-button').click
    first('.campaign-export-modal button.button--block').click
    expect(page).to have_content(I18n.t('campaign.data_download_generating'))
  end
end
