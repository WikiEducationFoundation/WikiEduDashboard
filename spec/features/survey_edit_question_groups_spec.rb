# frozen_string_literal: true

require 'rails_helper'

describe 'survey edit question groups page', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let!(:survey) { create(:survey) }

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit "/surveys/#{survey.id}/question_group"
    expect(page).to have_content 'Editing Question Groups'
    expect(page).to be_axe_clean
  end
end
