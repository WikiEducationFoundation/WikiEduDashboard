# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/retained_new_editors_stats"

describe RetainedNewEditorsStats do
  let(:course) { create(:course, start: 3.months.ago, end: 2.months.ago) }
  let(:manager) { described_class.new(course) }

  def add_student(username, registered_at:, retained: nil, checked: true)
    user = create(:user, username:, registered_at:)
    create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE,
           retained_after_course: retained,
           retained_after_course_checked_at: checked ? 1.day.ago : nil)
  end

  context 'when there are no new editors' do
    it 'returns 0' do
      expect(manager.count).to eq(0)
    end
  end

  context 'when every new editor has been checked' do
    before do
      add_student('Retained1', registered_at: course.start + 1.day, retained: true)
      add_student('Retained2', registered_at: course.start + 2.days, retained: true)
      add_student('NotRetained', registered_at: course.start + 3.days, retained: false)
    end

    it 'counts the new editors flagged as retained' do
      expect(manager.count).to eq(2)
    end

    it 'does not query the wiki API' do
      expect_any_instance_of(WikiApi).not_to receive(:query)
      manager.count
    end
  end

  context 'when a new editor could not be verified' do
    before do
      add_student('Retained', registered_at: course.start + 1.day, retained: true)
      add_student('Unverifiable', registered_at: course.start + 1.day, retained: nil)
    end

    it 'counts only the retained ones' do
      expect(manager.count).to eq(1)
    end
  end

  context 'when some new editors have not been checked yet' do
    before do
      add_student('Retained', registered_at: course.start + 1.day, retained: true)
      add_student('Unchecked', registered_at: course.start + 1.day, checked: false)
    end

    it 'returns nil because retention is still pending' do
      expect(manager.count).to be_nil
    end
  end

  context 'with students who are not new editors' do
    before do
      add_student('NewEditor', registered_at: course.start + 1.day, retained: true)
      add_student('OldAccount', registered_at: course.start - 1.year, retained: true)
    end

    it 'counts only students who registered during the course' do
      expect(manager.count).to eq(1)
    end
  end

  context 'with a retained instructor' do
    before do
      add_student('NewEditor', registered_at: course.start + 1.day, retained: true)
      instructor = create(:user, username: 'Instructor', registered_at: course.start + 1.day)
      create(:courses_user, course:, user: instructor,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE, retained_after_course: true,
             retained_after_course_checked_at: 1.day.ago)
    end

    it 'counts only students' do
      expect(manager.count).to eq(1)
    end
  end
end
