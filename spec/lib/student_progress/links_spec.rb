# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/student_progress/links"

describe StudentProgress::Links do
  let(:course) { create(:course, slug: 'School/Course_(Term)') }
  let(:student) { create(:user, username: 'Some Student') }
  let(:training) { build(:training_module, slug: 'a-training') }

  it 'links a training module with a return to the course page' do
    expect(described_class.training_url(course, training))
      .to eq("/training/#{course.training_library_slug}/a-training" \
             '?return_to=%2Fcourses%2FSchool%2FCourse_%28Term%29')
  end

  describe '.exercise_url' do
    it 'uses the exercise\'s in-app page when it has one' do
      allow(training).to receive(:exercise_path).and_return('verify_claim')
      expect(described_class.exercise_url(course, training))
        .to eq('/courses/School/Course_(Term)/verify_claim')
    end

    it 'falls back to the training page' do
      allow(training).to receive(:exercise_path).and_return(nil)
      expect(described_class.exercise_url(course, training))
        .to eq(described_class.training_url(course, training))
    end
  end

  describe '.exercise_sandbox_url' do
    it 'points at the fixed page under the student\'s userpage' do
      allow(training).to receive(:sandbox_location).and_return('Evaluate_an_Article')
      expect(described_class.exercise_sandbox_url(course, student, training))
        .to eq("#{student.userpage_url(course)}/Evaluate_an_Article")
    end

    it 'is nil for a module without a sandbox location' do
      allow(training).to receive(:sandbox_location).and_return(nil)
      expect(described_class.exercise_sandbox_url(course, student, training)).to be_nil
    end
  end
end
