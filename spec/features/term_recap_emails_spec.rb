# frozen_string_literal: true

require 'rails_helper'

describe 'term recap emails page', type: :feature do
  let(:admin) { create(:admin, email: 'admin@wikiedu.org') }
  let(:course) { create(:course, article_count: 2, end: 1.week.ago) }
  let(:active_course) do
    create(:course, slug: 'active', article_count: 10, user_count: 1,
           character_sum: 10_000, end: 1.day.ago)
  end
  let(:ongoing_course) do
    create(:course, slug: 'ongoing', article_count: 10, end: 1.week.from_now)
  end

  before do
    course.campaigns << Campaign.first
    active_course.campaigns << Campaign.first
    ongoing_course.campaigns << Campaign.first
    JoinCourse.new(course: course, user: admin, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    JoinCourse.new(course: active_course, user: admin, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    JoinCourse.new(course: ongoing_course, user: admin, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as admin
  end

  it 'lets admins send term recap emails' do
    visit '/mass_email/term_recap'

    expect(TermRecapMailer).to receive(:email).and_call_original
    expect(TermRecapMailer).to receive(:basic_email).and_call_original
    # ongoing course does not trigger any emails

    select(Campaign.first.title, from: 'campaign')
    click_button 'Send recap emails'
    expect(page).to have_content('Emails are going out')
  end
end
