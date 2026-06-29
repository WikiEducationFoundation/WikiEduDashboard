# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

describe Fall2026ResearchExperiment do
  let(:experiment) { described_class.new }
  let(:fall_2026_course) { create(:course, start: Date.new(2026, 9, 1)) }

  before { allow(Features).to receive(:wiki_ed?).and_return(true) }

  describe '#eligible_course?' do
    it 'is true for a Fall 2026 ClassroomProgramCourse' do
      expect(experiment.eligible_course?(fall_2026_course)).to be true
    end

    it 'is false for a course in another term' do
      course = create(:course, start: Date.new(2026, 1, 15))
      expect(experiment.eligible_course?(course)).to be false
    end

    it 'is false for a non-ClassroomProgramCourse' do
      course = create(:basic_course, start: Date.new(2026, 9, 1))
      expect(experiment.eligible_course?(course)).to be false
    end

    it 'is false when this is not the Wiki Education dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      expect(experiment.eligible_course?(fall_2026_course)).to be false
    end
  end

  describe '#course_participating?' do
    it 'is true only once an eligible course is tagged opted-in' do
      expect(experiment.course_participating?(fall_2026_course)).to be false
      create(:tag, course: fall_2026_course, tag: experiment.opted_in_tag)
      expect(experiment.course_participating?(fall_2026_course)).to be true
    end
  end

  describe 'student opt-in / opt-out' do
    let(:student) { create(:user) }
    let(:courses_user) do
      create(:courses_user, course: fall_2026_course, user: student,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    before { allow(Features).to receive(:disable_wiki_output?).and_return(true) }

    it 'records an opt-in and runs the intervention' do
      status = experiment.handle_student_opt_in(courses_user)
      expect(experiment.participation(courses_user).opted_in?).to be true
      expect(status).to eq(:disabled) # the userscript edit is suppressed in test
    end

    it 'records an opt-out without running an intervention' do
      experiment.handle_student_opt_out(courses_user)
      expect(experiment.participation(courses_user).opted_out?).to be true
    end

    it 'no longer needs a response once the student has responded' do
      create(:tag, course: fall_2026_course, tag: experiment.opted_in_tag)
      expect(experiment.needs_response?(courses_user)).to be true
      experiment.handle_student_opt_in(courses_user)
      expect(experiment.needs_response?(courses_user)).to be false
    end
  end

  describe '.for_course' do
    it 'finds the active experiment a course is eligible for' do
      expect(OptInExperiment.for_course(fall_2026_course)).to be_a(described_class)
    end
  end
end
