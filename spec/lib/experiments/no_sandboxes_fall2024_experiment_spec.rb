# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/no_sandboxes_fall_2024_experiment"

describe NoSandboxesFall2024Experiment do
  def fresh_course
    course = create(:course, start: '2024-07-01'.to_date)
    user = create(:user)
    create(:courses_user, course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    return [course, user]
  end

  def delete_course
    Course.last.destroy
    User.last.destroy
  end

  it 'randomly assigns some courses to experiment or control, up to 50 times' do
    experiment_count = 0
    control_count = 0
    200.times do
      described_class.new(*fresh_course)
      experiment_count += 1 if Course.last.tag?(described_class::EXPERIMENT_TAG)
      control_count += 1 if Course.last.tag?(described_class::CONTROL_TAG)
      delete_course
    end
    expect(experiment_count).to eq(50)
    setting_count = Setting.find_by(key: 'no_sandbox_fall_2024_experiment').value
    expect(setting_count[:experiment_condition_count]).to eq(50)
  end

  context 'when the same instructor has multiple courses' do
    it 'puts a new course into control if the first one is control' do
      course, user = *fresh_course
      create(:tag, course:, tag: described_class::CONTROL_TAG)
      second_course = create(:course, slug: 'experiment/second_course', start: '2024-07-01'.to_date)
      create(:courses_user, course: second_course, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      expect(described_class.control_courses.count).to eq(1)
      described_class.new(second_course, user)
      expect(second_course.tag?(described_class::CONTROL_TAG)).to eq(true)
    end

    it 'puts a new course into experiment if the first one is experiment' do
      course, user = *fresh_course
      create(:tag, course:, tag: described_class::EXPERIMENT_TAG)
      second_course = create(:course, slug: 'experiment/second_course', start: '2024-07-01'.to_date)
      create(:courses_user, course: second_course, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      expect(described_class.experiment_courses.count).to eq(1)
      described_class.new(second_course, user)
      expect(second_course.tag?(described_class::EXPERIMENT_TAG)).to eq(true)
    end
  end
end
