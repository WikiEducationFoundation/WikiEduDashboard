# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/fall2017_cmu_experiment"

describe Fall2017CmuExperiment do
  let(:fall_2017) { create(:campaign, slug: 'fall_2017') }
  let(:user) { create(:user, email: 'sage@example.com') }

  before do
    10.times do |i|
      course = create(:course, slug: "fall course number #{i}", id: i)
      course.campaigns << fall_2017
      create(:courses_user, course: course, user: user,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
  end

  describe '.process_courses' do
    it 'divides courses between experiment and control, and updates experiment setting' do
      Fall2017CmuExperiment.process_courses
      control_courses = Course.all.select do |c|
        c.flags[Fall2017CmuExperiment::STATUS_KEY] == 'control'
      end
      expect(control_courses.count).to eq(3)
      emailed_courses = Course.all.select do |c|
        c.flags[Fall2017CmuExperiment::STATUS_KEY] == 'email_sent'
      end
      expect(emailed_courses.count).to eq(7)
      experiment_setting = Setting.find_by(key: 'fall_2017_cmu_experiment')
      expect(experiment_setting.value[:enrolled_courses_count]).to eq(10)
    end

    context 'when invitations get no response for a week' do
      after { Timecop.return }
      it 'sends reminders for courses that have not responded' do
        Fall2017CmuExperiment.process_courses
        Timecop.travel(8.days.from_now)
        Fall2017CmuExperiment.process_courses
        reminded_courses = Course.all.select do |c|
          c.flags[Fall2017CmuExperiment::STATUS_KEY] == 'reminder_sent'
        end
        expect(reminded_courses.count).to eq(7)
      end
    end
  end

  let(:course) { create(:course, flags: { Fall2017CmuExperiment::STATUS_KEY => 'email_sent' }) }

  describe '#opt_in and #opt_out' do
    it 'updates the experiment status of a course to opted_in' do
      Fall2017CmuExperiment.new(course).opt_in
      expect(course.flags[Fall2017CmuExperiment::STATUS_KEY]).to eq('opted_in')
    end
  end

  describe '#opt_out' do
    it 'updates the experiment status of a course to opted_out' do
      Fall2017CmuExperiment.new(course).opt_out
      expect(course.flags[Fall2017CmuExperiment::STATUS_KEY]).to eq('opted_out')
    end
  end
end
