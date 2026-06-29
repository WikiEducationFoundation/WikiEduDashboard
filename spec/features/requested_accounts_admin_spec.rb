# frozen_string_literal: true

require 'rails_helper'

describe 'requested accounts admin pages', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course, flags: { register_accounts: true }) }
  let!(:requested) do
    RequestedAccount.create(course: course, username: 'ExampleUser', email: 'example@example.com')
  end

  before { login_as(admin) }
  after { logout }

  it 'index loads cleanly' do
    visit '/requested_accounts'
    expect(page).to have_content 'Requested accounts'
    expect(page).to be_axe_clean
  end

  it 'show loads cleanly' do
    visit "/requested_accounts/#{course.slug}"
    expect(page).to have_content 'Requested accounts'
    expect(page).to be_axe_clean
  end
end
