# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/workers/course_data_update_worker"

describe CourseDataUpdateWorker do
  let(:course) { create(:course) }

  it 'handles deleted courses' do
    course.destroy
    expect(Sentry).to receive(:capture_exception)
    described_class.update_course(course_id: course.id, queue: 'default')
  end

  it 'skips courses flagged very_long_update' do
    course.update(flags: { very_long_update: true })
    expect(UpdateCourseStats).not_to receive(:new)
    described_class.new.perform(course.id)
  end
end
