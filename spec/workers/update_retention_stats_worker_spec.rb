# frozen_string_literal: true

require 'rails_helper'

describe UpdateRetentionStatsWorker do
  let(:recent) do
    create(:course, type: 'FellowsCohort', slug: 'S/recent', start: 60.days.ago, end: 10.days.ago)
  end
  let(:old) do
    create(:course, type: 'FellowsCohort', slug: 'S/old', start: 300.days.ago, end: 200.days.ago)
  end
  let(:running) do
    create(:course, type: 'FellowsCohort', slug: 'S/running', start: 10.days.ago,
                    end: 10.days.from_now)
  end
  let(:student_program) do
    create(:course, slug: 'S/classroom', start: 60.days.ago, end: 10.days.ago)
  end
  let(:current) do
    create(:course, type: 'FellowsCohort', slug: 'S/current', start: 60.days.ago, end: 10.days.ago)
  end

  before do
    allow(UpdateCourseRetentionStats).to receive(:new)
    student = create(:user, username: 'student')
    create(:courses_user, course: current, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:retention_stat, course: current, user: student, computed_at: 2.days.ago)
    [recent, old, running, student_program]
  end

  it 'recomputes only recently ended Scholars & Scientists courses that are due' do
    described_class.new.perform
    expect(UpdateCourseRetentionStats).to have_received(:new).once
    expect(UpdateCourseRetentionStats).to have_received(:new)
      .with(an_object_having_attributes(slug: 'S/recent'), now: kind_of(Time))
  end
end
