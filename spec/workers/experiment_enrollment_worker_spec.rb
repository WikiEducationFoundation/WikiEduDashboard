# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

describe ExperimentEnrollmentWorker do
  let(:course) { create(:course, start: Date.new(2026, 9, 1)) }
  let(:student) { create(:user) }
  let(:courses_user) do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  def create_record(status)
    ExperimentCoursesUser.create!(experiment_slug: Fall2026ResearchExperiment::SLUG,
                                  courses_user:, status:)
  end

  it 'reports an opted-in record to the experiment' do
    record = create_record(:opted_in)
    expect_any_instance_of(Fall2026ResearchExperiment)
      .to receive(:report_enrollment).with(record)
    described_class.new.perform(record.id)
  end

  it 'does nothing for an opted-out record' do
    record = create_record(:opted_out)
    expect_any_instance_of(Fall2026ResearchExperiment).not_to receive(:report_enrollment)
    described_class.new.perform(record.id)
  end

  it 'does nothing when the record no longer exists' do
    expect_any_instance_of(Fall2026ResearchExperiment).not_to receive(:report_enrollment)
    described_class.new.perform(-1)
  end
end
