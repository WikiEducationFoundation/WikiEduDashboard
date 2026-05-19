# frozen_string_literal: true

require 'rails_helper'

describe 'AI tools admin page', type: :feature, js: true do
  let(:admin) { create(:admin) }

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit '/ai_tools'
    expect(page).to have_content 'AI Tools'
    expect(page).to be_axe_clean
  end
end
