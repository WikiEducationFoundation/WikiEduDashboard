# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_csv_builder"

describe CourseCsvBuilder do
  let(:course) { create(:course, start: 90.days.ago, end: 40.days.ago) }
  let(:subject) { described_class.new(course, per_wiki: true).generate_csv }

  def add_student(username, registered_at:, retained: nil, checked_at: nil)
    user = create(:user, username:, registered_at:)
    create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE,
                          retained_after_course: retained,
                          retained_after_course_checked_at: checked_at)
  end

  def retained_new_editors_cell
    rows = CSV.parse(subject)
    rows[1][rows[0].index('retained_new_editors')]
  end

  it 'creates a CSV with a header and a row of data' do
    expect(subject.split("\n").count).to eq(2)
  end

  context 'when every new editor has been checked for retention' do
    before do
      add_student('Retained', registered_at: 80.days.ago, retained: true, checked_at: 1.day.ago)
      add_student('Lapsed', registered_at: 80.days.ago, retained: false, checked_at: 1.day.ago)
    end

    it 'counts the new editors recorded as retained' do
      expect(retained_new_editors_cell).to eq('1')
    end
  end

  context 'when a new editor has not been checked yet' do
    before do
      add_student('Retained', registered_at: 80.days.ago, retained: true, checked_at: 1.day.ago)
      add_student('Pending', registered_at: 80.days.ago)
    end

    it 'leaves the count blank' do
      expect(retained_new_editors_cell).to be_nil
    end
  end

  context 'when a student registered before the course' do
    before do
      add_student('Veteran', registered_at: 2.years.ago, retained: true, checked_at: 1.day.ago)
    end

    it 'does not count them as a retained new editor' do
      expect(retained_new_editors_cell).to eq('0')
    end
  end
end
