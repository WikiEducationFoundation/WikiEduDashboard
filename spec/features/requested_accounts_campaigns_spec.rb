# frozen_string_literal: true

require 'rails_helper'

describe 'requested accounts campaigns admin pages', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:campaign) { create(:campaign, register_accounts: true) }
  let(:course) { create(:course) }
  let!(:campaigns_course) do
    create(:campaigns_course, campaign_id: campaign.id, course_id: course.id)
  end
  let!(:requested) do
    RequestedAccount.create(course: course, username: 'ExampleUser', email: 'example@example.com')
  end

  before { login_as(admin) }
  after { logout }

  it 'index loads cleanly' do
    visit "/requested_accounts_campaigns/#{campaign.slug}"
    expect(page).to have_content 'Requested accounts'
    expect(page).to be_axe_clean
  end
end
