# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('app/workers/course_data_update_worker')

describe CourseDataUpdateWorker do
  let(:course) { create(:course) }

  it 'handles deleted courses' do
    course.destroy
    expect(Sentry).to receive(:capture_exception)
    described_class.update_course(course_id: course.id, queue: 'default')
  end
end
