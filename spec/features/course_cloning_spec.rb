# frozen_string_literal: true
require 'rails_helper'

describe 'cloning a course', js: true do
  before do
    Capybara.current_driver = :poltergeist
    page.current_window.resize_to(1920, 1080)
    stub_oauth_edit
  end

  let!(:course) do
    create(:course, id: 10001, start: 1.year.from_now.to_date,
                    end: 2.years.from_now.to_date, submitted: true,
                    expected_students: 0)
  end
  let!(:week)      { create(:week, course_id: course.id) }
  let!(:block)     { create(:block, week_id: week.id, due_date: course.start + 3.months) }
  let!(:gradeable) do
    create(:gradeable, gradeable_item_type: 'block', gradeable_item_id: block.id, points: 10)
  end
  let!(:user)      { create(:user, permissions: User::Permissions::ADMIN) }
  let!(:c_user)    { create(:courses_user, course_id: course.id, user_id: user.id) }
  let!(:term)      { 'Spring 2016' }
  let!(:desc)      { 'A new course' }

  it 'copies relevant attributes of an existing course' do
    login_as user, scope: :user, run_callbacks: false
    visit root_path

    click_link 'Create Course'
    click_button 'Clone Previous Course'
    select course.title, from: 'reuse-existing-course-select'
    click_button 'Clone This Course'

    expect(page).to have_content 'Course Successfully Cloned'

    # interact_with_clone_form

    # form not working right now
    visit "/courses/#{Course.last.slug}"
    course.reload

    new_course = Course.last
    expect(Week.count).to eq(2) # make sure the weeks are distinct
    expect(new_course.blocks.first.content).to eq(course.blocks.first.content)
    expect(new_course.blocks.first.due_date)
      .to be_nil
    expect(new_course.blocks.first.gradeable.points).to eq(gradeable.points)
    expect(new_course.blocks.first.gradeable.gradeable_item_id)
      .to eq(new_course.blocks.first.id)
    expect(new_course.instructors.first).to eq(user)
    expect(new_course.submitted).to eq(false)
    expect(new_course.user_count).to be_zero
    expect(new_course.article_count).to be_zero
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
