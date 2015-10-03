require 'rails_helper'
require "#{Rails.root}/lib/course_clone_manager"

describe CourseCloneManager do
  before do
    create(:course,
           id: 1,
           school: 'School',
           term: 'Term',
           title: 'Title',
           start: 1.year.ago,
           end: 8.months.ago,
           timeline_start: 11.months.ago,
           timeline_end: 9.months.ago,
           slug: 'School/Title_(Term)',
           passcode: 'code')
    create(:cohort, id: 1)
    create(:cohorts_course, course_id: 1, cohort_id: 1)
    create(:user, id: 1)
    create(:courses_user,
           user_id: 1,
           course_id: 1,
           role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:user, id: 2)
    create(:courses_user,
           user_id: 2,
           course_id: 1,
           role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:week, id: 1, course_id: 1, title: 'Week 1')
    create(:block,
           id: 1, week_id: 1, content: 'First Assignment',
           kind: 1, due_date: 10.months.ago, gradeable_id: 1)
    create(:gradeable,
           id: 1, gradeable_item_type: 'block',
           gradeable_item_id: 1, points: 15)
  end

  it 'should create a new course based on an old one' do
    original = Course.find(1)
    instructor = User.find(1)
    clone = CourseCloneManager.new(original, instructor).clone!
    # The creating instructor should carry over.
    expect(clone.instructors.first).to eq(instructor)
    # The students should not carry over.
    expect(clone.students).to be_empty
    # A new passcode should be created.
    expect(clone.passcode).not_to eq(original.passcode)
    # Course dates should not carry over.
    expect(clone.start).not_to eq(original.start)
    expect(clone.end).not_to eq(original.end)
    expect(clone.timeline_start).not_to eq(original.timeline_start)
    expect(clone.timeline_end).not_to eq(original.timeline_end)

    # Cohorts should not carry over.
    expect(clone.cohorts).to be_empty

    # The weeks and block content should carry over.
    expect(clone.weeks.first.title).to eq('Week 1')
    expect(clone.weeks.first.blocks.first.content).to eq('First Assignment')

    # Block due dates, which are stored relative to the assignment dates,
    # should be unset.
    expect(clone.weeks.first.blocks.first.due_date).to be_nil

    # Gradeables should carry over.
    expect(clone.weeks.first.blocks.first.gradeable.points).to eq(15)
  end
end
