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
    create(:week, id: 1, course_id: 1, order: 1)
    create(:block,
           id: 1, week_id: 1, content: 'First Assignment',
           kind: 1, due_date: 10.months.ago, gradeable_id: 1)
    create(:gradeable,
           id: 1, gradeable_item_type: 'block',
           gradeable_item_id: 1, points: 15)


  end

  let(:clone) { Course.last }
  let(:original) { Course.find(1) }
  let(:instructor) { User.find(1) }

  context 'newly cloned course' do
    before do
      CourseCloneManager.new(Course.find(1), User.find(1)).clone!
    end

    it 'has creating instructor carried over' do
      expect(clone.instructors.first).to eq(instructor)
    end

    it 'does not carry over students' do
      expect(clone.students).to be_empty
    end

    it 'has a new passcode' do
      expect(clone.passcode).not_to eq(original.passcode)
    end

    it 'does not carry over course dates' do
      expect(clone.start).not_to eq(original.start)
      expect(clone.end).not_to eq(original.end)
      expect(clone.timeline_start).not_to eq(original.timeline_start)
      expect(clone.timeline_end).not_to eq(original.timeline_end)
    end

    it 'does not carry over cohorts' do
      expect(clone.cohorts).to be_empty
    end

    it 'has weeks and block content from original' do
      expect(clone.weeks.first.order).to eq(1)
      expect(clone.weeks.first.blocks.first.content).to eq('First Assignment')
    end

    it 'unsets block due dates' do
      # Block due dates, which are stored relative to the assignment dates,
      # should be unset.
      expect(clone.weeks.first.blocks.first.due_date).to be_nil
    end

    it 'carries over gradeables' do
      # Gradeables should carry over.
      expect(clone.weeks.first.blocks.first.gradeable.points).to eq(15)
    end

    it 'adds tags new/returning and for cloned status' do
      tags = clone.tags.pluck(:tag)
      expect(tags).to include('cloned')
      expect(tags).to include('returning_instructor')
    end
  end

  context 'cloned LegacyCourse' do
    before do
      Course.find(1).update_attributes(type: 'LegacyCourse')
      CourseCloneManager.new(Course.find(1), User.find(1)).clone!
    end

    it 'sets the new course type to ClassroomProgramCourse' do
      expect(clone.type).to eq('ClassroomProgramCourse')
    end
  end
end
