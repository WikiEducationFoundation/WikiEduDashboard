# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

# Covers the standalone instructor opt-in page reached from invitation emails,
# for instructors whose courses never went through the assignment wizard. The
# page is server-rendered with no JavaScript, so these run on rack_test.
describe 'research experiment instructor email-link opt-in', type: :feature do
  let(:experiment) { Fall2026ResearchExperiment.new }
  let(:instructor) do
    create(:user, username: 'Alice Nakamura', permissions: User::Permissions::INSTRUCTOR)
  end
  let(:opt_in_path) { "/experiments/#{experiment.slug}/instructor_optin" }

  before do
    allow(Features).to receive(:wiki_ed?).and_return(true)
  end

  after { logout }

  def eligible_course(title)
    create(:course, title:, school: 'Northwestern University',
                    slug: "Northwestern_University/#{title.tr(' ', '_')}_(Fall_2026)",
                    start: Date.new(2026, 9, 1), end: Date.new(2026, 12, 15))
  end

  def instruct(course)
    create(:courses_user, user: instructor, course:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  it 'asks a signed-out visitor to log in, keeping the page as the return path' do
    visit opt_in_path
    expect(page).to have_content('Log in')
  end

  context 'for a signed-in instructor with eligible courses' do
    let!(:environmental_policy) { eligible_course('Environmental Policy').tap { |c| instruct(c) } }
    let!(:media_literacy) do
      eligible_course('Media Literacy').tap do |course|
        instruct(course)
        Tag.create!(course:, key: experiment.tag_key, tag: experiment.opted_out_tag)
      end
    end
    # A Spring 2026 course is not part of the experiment and must not be listed.
    let!(:spring_course) do
      create(:course, title: 'History of Science',
                      slug: 'Northwestern_University/History_of_Science_(Spring_2026)',
                      start: Date.new(2026, 1, 15), end: Date.new(2026, 5, 15))
        .tap { |c| instruct(c) }
    end

    before { login_as(instructor, scope: :user) }

    it 'shows the wizard panel info and each course with its current status' do
      visit opt_in_path
      expect(page).to have_content('Please participate in our research experiment')
      expect(page).to have_content('Wiki Education is working with researchers')
      expect(page).to have_content('Environmental Policy')
      expect(page).to have_content('Media Literacy')
      expect(page).to have_content('Undecided')
      expect(page).to have_content('Opted out')
      expect(page).to have_no_content('History of Science')
    end

    it 'opts in all eligible courses, overriding an earlier opt-out' do
      visit opt_in_path
      click_button 'Yes, my class will participate'
      expect(page).to have_content('Thank you! Your Fall 2026 courses are opted in')
      expect(experiment.course_choice(environmental_policy)).to eq(:opted_in)
      expect(experiment.course_choice(media_literacy)).to eq(:opted_in)
      expect(experiment.course_participating?(media_literacy)).to be true
      expect(experiment.course_choice(spring_course)).to be_nil
    end

    it 'opts out all eligible courses' do
      visit opt_in_path
      click_button 'No, I want to opt out'
      expect(page).to have_content('You have opted out.')
      expect(experiment.course_choice(environmental_policy)).to eq(:opted_out)
      expect(experiment.course_choice(media_literacy)).to eq(:opted_out)
    end
  end

  it 'explains when a signed-in user has no eligible courses' do
    login_as(instructor, scope: :user)
    visit opt_in_path
    expect(page).to have_content("You don't have any Fall 2026 courses")
    expect(page).to have_no_button('Yes, my class will participate')
  end
end
