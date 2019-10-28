# frozen_string_literal: true

require 'rails_helper'

describe 'term recap emails page', type: :feature do
  let(:admin) { create(:admin, email: 'admin@wikiedu.org') }
  let(:course) { create(:course, article_count: 2) }

  before do
    course.campaigns << Campaign.first
    JoinCourse.new(course: course, user: admin, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as admin
  end

  it 'lets admins send term recap emails' do
    visit '/mass_email/term_recap'

    select(Campaign.first.title, from: 'campaign')
    click_button 'Send recap emails'
    expect(page).to have_content('Emails are going out')
  end
end
