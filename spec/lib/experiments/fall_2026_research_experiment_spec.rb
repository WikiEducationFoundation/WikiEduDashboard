# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

describe Fall2026ResearchExperiment do
  let(:experiment) { described_class.new }
  let(:fall_2026_course) { create(:course, start: Date.new(2026, 9, 1)) }

  before do
    allow(Features).to receive(:wiki_ed?).and_return(true)
    allow(Features).to receive(:fall_2026_research_student_optin?).and_return(true)
  end

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

    it 'records an opt-in, leaving the userscript still to be installed' do
      experiment.handle_student_opt_in(courses_user)
      record = experiment.participation(courses_user)
      expect(record.opted_in?).to be true
      expect(record.userscript_installed_at).to be_nil
    end

    it 'records an opt-out' do
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

  describe 'holding back the student side' do
    let(:student) { create(:user) }
    let(:courses_user) do
      create(:courses_user, course: fall_2026_course, user: student,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    before do
      allow(Features).to receive(:fall_2026_research_student_optin?).and_return(false)
      create(:tag, course: fall_2026_course, tag: experiment.opted_in_tag)
    end

    it 'still lets an instructor opt the course in' do
      expect(fall_2026_course.eligible_for_active_research_experiment?).to be true
      expect(experiment.course_participating?(fall_2026_course)).to be true
    end

    it 'does not invite enrolled students' do
      expect(experiment.needs_response?(courses_user)).to be false
      expect(experiment.open_to_student?(courses_user)).to be false
    end

    it 'keeps the course JSON from advertising the experiment to students' do
      expect(fall_2026_course.research_experiment_open_to_students?).to be false
    end
  end

  describe '#userscript_install_url' do
    let(:student) { create(:user, username: 'Ada Lovelace') }

    it 'points at the student own common.js edit form' do
      url = experiment.userscript_install_url(student)
      expect(url).to start_with('https://en.wikipedia.org/w/index.php?')
      expect(url).to include(CGI.escape('User:Ada Lovelace/common.js'))
      expect(url).to include('action=edit')
    end

    # MediaWiki's ContentHandler::supportsPreloadContent is false for the
    # javascript content model, so a preload parameter would be ignored.
    it 'does not try to preload the edit box' do
      expect(experiment.userscript_install_url(student)).not_to include('preload')
    end
  end

  describe '#userscript_marker' do
    it 'is contained in the import line, so a saved line is detected' do
      expect(experiment.userscript_import_line).to include(experiment.userscript_marker)
    end
  end

  describe '.for_course' do
    it 'finds the active experiment a course is eligible for' do
      expect(OptInExperiment.for_course(fall_2026_course)).to be_a(described_class)
    end
  end
end
