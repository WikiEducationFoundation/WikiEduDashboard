# frozen_string_literal: true

require 'rails_helper'

describe 'individual alert page', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let!(:alert) do
    Alert.create(course: course, user: user, message: 'a problem', type: 'NoEnrolledStudentsAlert')
  end

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit "/alerts_list/#{alert.id}"
    expect(page).to have_content 'NoEnrolledStudentsAlert'
    expect(page).to be_axe_clean
  end
end
