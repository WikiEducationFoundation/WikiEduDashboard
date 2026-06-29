# frozen_string_literal: true

require 'rails_helper'

describe 'users admin lookup page', type: :feature, js: true do
  let(:admin) { create(:admin) }

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit '/users'
    expect(page).to have_content 'Users'
    expect(page).to be_axe_clean
  end
end
