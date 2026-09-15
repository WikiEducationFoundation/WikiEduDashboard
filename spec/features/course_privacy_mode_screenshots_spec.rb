# frozen_string_literal: true

require 'rails_helper'

# `if: ENV['SCREENSHOT']` keeps this out of the default suite — it only defines
# itself when bin/pr-screenshots sets the env var.
describe 'Course privacy mode screenshots', type: :feature, js: true,
                                            if: ENV['SCREENSHOT'] do
  let(:screenshot_dir) { Rails.root.join('tmp/screenshots', ENV['SCREENSHOT']) }

  before do
    FileUtils.mkdir_p(screenshot_dir)
    page.current_window.resize_to(1440, 1000)
    TrainingModule.load_all
    stub_oauth_edit
    user = create(:user, id: 1, permissions: User::Permissions::INSTRUCTOR)
    create(:training_modules_users, user_id: user.id, training_module_id: 3,
                                    completed_at: Time.zone.now)
    login_as(user, scope: :user)
    visit root_path
  end

  after { logout }

  def shoot(name)
    sleep 0.3 # let transitions settle
    page.save_screenshot(screenshot_dir.join("#{name}.png"))
  end

  it 'captures the privacy-mode checkbox and the resulting course page' do
    click_link 'Create Course'
    expect(page).to have_content 'Create a New Course'
    find('#course_title').set('Introduction to Biology')
    find('#course_school').set('State University')
    find('#course_term').set('Fall 2026')
    shoot('01_course_creator_privacy_checkbox')

    find('#course_confidential').click
    shoot('02_privacy_mode_selected')
  end

  it 'captures a privacy-mode course page as its instructor' do
    course = create(:course, title: 'Course 1', school: 'Confidential',
                             term: 'Fall 2026', slug: 'Confidential/Course_1_(Fall_2026)',
                             start: 1.month.ago, end: 1.month.from_now)
    create(:confidential_course_detail, course:, real_title: 'Introduction to Biology',
                                        real_school: 'State University')
    create(:courses_user, course:, user: User.find(1),
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE,
                          real_name: 'Jane Q. Instructor')
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'Course 1'
    shoot('03_privacy_mode_course_page')
  end
end
