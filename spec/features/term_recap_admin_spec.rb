# frozen_string_literal: true

require 'rails_helper'

describe 'term recap admin page', type: :feature, js: true do
  let(:admin) { create(:admin) }

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit '/mass_email/term_recap'
    expect(page).to have_content 'Term Recap Emails'
    expect(page).to be_axe_clean
  end
end
