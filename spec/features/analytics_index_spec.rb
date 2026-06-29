# frozen_string_literal: true

require 'rails_helper'

describe 'analytics index page', type: :feature, js: true do
  let(:admin) { create(:admin) }

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit '/analytics'
    expect(page).to have_content 'Analytics Tools'
    expect(page).to be_axe_clean
  end
end
