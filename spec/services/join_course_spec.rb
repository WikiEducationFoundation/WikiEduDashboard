# frozen_string_literal: true

require 'rails_helper'

describe JoinCourse do
  let(:user) { create(:user) }
  let(:classroom_program_course) { create(:course) }
  let(:visiting_scholarship) { create(:visiting_scholarship) }
  let(:editathon) { create(:editathon) }
  let(:basic_course) { create(:basic_course) }
  let(:legacy_course) { create(:legacy_course) }

  let(:subject) do
    described_class.new(course: course, user: user,
                        role: CoursesUsers::Roles::STUDENT_ROLE)
  end
  let(:enroll_as_instructor) do
    described_class.new(course: course, user: user,
                        role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  before(:each) do
    course.campaigns << Campaign.first
    enroll_as_instructor
  end

  context 'with real name' do
    let(:course) { create(:basic_course) }
    let(:subject) do
      described_class.new(course: course, user: user,
                          role: CoursesUsers::Roles::STUDENT_ROLE,
                          real_name: 'student name')
    end
    it 'allows a course to be joined' do
      result = subject.result
      expect(result[:failure]).to be_nil
      expect(result[:success]).to_not be_nil
    end
  end

  context 'without real name' do
    let(:course) { create(:basic_course) }
    let(:subject) do
      described_class.new(course: course, user: user,
                          role: CoursesUsers::Roles::STUDENT_ROLE,
                          real_name: nil)
    end
    it 'allows a course to be joined' do
      result = subject.result
      expect(result[:failure]).to be_nil
      expect(result[:success]).to_not be_nil
    end
  end

  context 'for a ClassroomProgramCourse' do
    let(:course) { classroom_program_course }
    it 'does not allow joining with multiple roles' do
      result = subject.result
      expect(result[:failure]).not_to be_nil
      expect(result[:success]).to be_nil
    end
  end

  context 'for an Editathon' do
    let(:course) { editathon }
    it 'allows joining with multiple roles' do
      result = subject.result
      expect(result[:failure]).to be_nil
      expect(result[:success]).not_to be_nil
    end
  end

  context 'for a BasicCourse' do
    let(:course) { basic_course }
    it 'allows joining with multiple roles' do
      result = subject.result
      expect(result[:failure]).to be_nil
      expect(result[:success]).not_to be_nil
    end
  end

  context 'for a LegacyCourse' do
    let(:course) { legacy_course }
    it 'allows joining with multiple roles' do
      result = subject.result
      expect(result[:failure]).to be_nil
      expect(result[:success]).not_to be_nil
    end
  end

  context 'for a VisitingScholarship' do
    let(:course) { visiting_scholarship }
    it 'allows joining with multiple roles' do
      result = subject.result
      expect(result[:failure]).to be_nil
      expect(result[:success]).not_to be_nil
    end
  end
end
