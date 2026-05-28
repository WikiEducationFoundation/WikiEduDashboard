# frozen_string_literal: true

require 'rails_helper'

describe 'survey course-select page', type: :feature, js: true do
  let(:user) { create(:admin) }
  let(:survey) { create(:survey, name: 'My Survey') }
  let!(:course) { create(:course) }

  before { login_as(user) }
  after { logout }

  it 'loads cleanly' do
    visit "/surveys/select_course/#{survey.id}"
    expect(page).to have_content 'My Survey'
    expect(page).to be_axe_clean
  end
end
