# frozen_string_literal: true

require 'rails_helper'

describe 'system status page', type: :feature, js: true do
  it 'loads cleanly' do
    visit '/status'
    expect(page).to have_content I18n.t('status.queues_overview')
    expect(page).to be_axe_clean
  end
end
