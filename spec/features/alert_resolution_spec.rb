# frozen_string_literal: true

require 'rails_helper'

# alerts#resolve only resolves on PUT; a GET goes to the alert's page.
describe 'resolving an alert', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let!(:alert) do
    Alert.create(course:, user:, message: 'a problem', type: 'OverEnrollmentAlert')
  end

  before { login_as(admin) }
  after { logout }

  it 'resolves from the alerts list' do
    visit '/alerts_list'
    expect(page).to have_content 'OverEnrollmentAlert'
    click_button 'Resolve'
    # The list marks the alert resolved once the request returns, even if it failed.
    expect(page).not_to have_button 'Resolve'
    expect(alert.reload.resolved).to be(true)
  end

  it 'resolves from the alert\'s page' do
    visit "/alerts_list/#{alert.id}"
    click_link 'Resolve'
    expect(page).not_to have_link 'Resolve'
    expect(alert.reload.resolved).to be(true)
  end
end
