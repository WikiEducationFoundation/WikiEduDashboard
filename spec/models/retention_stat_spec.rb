# frozen_string_literal: true

require 'rails_helper'

describe RetentionStat do
  let(:course) { create(:course, type: 'FellowsCohort', start: 100.days.ago, end: 40.days.ago) }
  let(:student) { create(:user, username: 'student') }

  before do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  describe '.update_due?' do
    it 'is not due before the first checkpoint, a day after the course ends' do
      course.update(end: 12.hours.ago)
      expect(described_class.update_due?(course)).to be(false)
    end

    it 'is due once the course has ended and nothing has been stored' do
      expect(described_class.update_due?(course)).to be(true)
    end

    it 'is not due for a course with no students, since there is nothing to store' do
      course.courses_users.delete_all
      expect(described_class.update_due?(course)).to be(false)
    end

    it 'is due when a metric window has closed since the rows were computed' do
      # Computed 5 days after the end, before the 30-day return window closed.
      create(:retention_stat, course:, user: student, computed_at: 35.days.ago)
      expect(described_class.update_due?(course)).to be(true)
    end

    it 'is not due when the rows are as complete as the calendar allows' do
      # Computed 35 days after the end; the survival window is still open now.
      create(:retention_stat, course:, user: student, computed_at: 5.days.ago)
      expect(described_class.update_due?(course)).to be(false)
    end

    it 'is due when the roster has changed since the rows were computed' do
      create(:retention_stat, course:, user: student, computed_at: 5.days.ago)
      create(:courses_user, course:, user: create(:user, username: 'late'),
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      expect(described_class.update_due?(course)).to be(true)
    end

    it 'is never due again after the final checkpoint' do
      course.update(end: 100.days.ago)
      create(:retention_stat, course:, user: student, computed_at: 5.days.ago)
      expect(described_class.update_due?(course)).to be(false)
    end
  end

  describe '#returning?' do
    it 'is true for a participant who took an earlier course' do
      expect(described_class.new(prior_course_count: 1)).to be_returning
      expect(described_class.new(prior_course_count: 0)).not_to be_returning
    end
  end
end
