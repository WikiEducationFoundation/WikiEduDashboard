# frozen_string_literal: true

require 'rails_helper'

describe 'updating locale via URL', type: :feature do
  let(:user) { create(:user) }

  before { login_as(user) }

  it 'updates the locale and redirects to the home page' do
    expect(user.locale).to be_nil
    visit '/update_locale/ar'
    expect(user.reload.locale).to eq('ar')
    expect(page).to have_content('مرحبا')
  end
end
