# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/experiments/fall2017_cmu_experiment')

describe Fall2017CmuExperiment do
  let(:fall_2017) { create(:campaign, slug: 'fall_2017') }
  let(:user) { create(:user, email: 'sage@example.com') }

  before do
    4.times do |i|
      course = create(:course, slug: "fall course number #{i}", id: i)
      course.campaigns << fall_2017
      create(:courses_user, course:, user:,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
  end

  let(:course) { create(:course, flags: { Fall2017CmuExperiment::STATUS_KEY => 'email_sent' }) }

  describe '.process_courses' do
    it 'divides courses between experiment and control, and updates experiment setting' do
      described_class.process_courses
      control_courses = Course.all.select do |c|
        c.flags[Fall2017CmuExperiment::STATUS_KEY] == 'control'
      end
      expect(control_courses.count).to eq(1)
      emailed_courses = Course.all.select do |c|
        c.flags[Fall2017CmuExperiment::STATUS_KEY] == 'email_sent'
      end
      expect(emailed_courses.count).to eq(3)
      experiment_setting = Setting.find_by(key: 'fall_2017_cmu_experiment')
      expect(experiment_setting.value[:enrolled_courses_count]).to eq(4)
    end

    context 'when invitations get no response for a week' do
      after { travel_back }

      it 'sends reminders for courses that have not responded' do
        described_class.process_courses
        travel(8.days)
        described_class.process_courses
        reminded_courses = Course.all.select do |c|
          c.flags[Fall2017CmuExperiment::STATUS_KEY] == 'reminder_sent'
        end
        expect(reminded_courses.count).to eq(3)
      end
    end
  end

  describe '#opt_in and #opt_out' do
    it 'updates the experiment status of a course to opted_in' do
      described_class.new(course).opt_in
      expect(course.flags[Fall2017CmuExperiment::STATUS_KEY]).to eq('opted_in')
    end
  end

  describe '#opt_out' do
    it 'updates the experiment status of a course to opted_out' do
      described_class.new(course).opt_out
      expect(course.flags[Fall2017CmuExperiment::STATUS_KEY]).to eq('opted_out')
    end
  end
end
