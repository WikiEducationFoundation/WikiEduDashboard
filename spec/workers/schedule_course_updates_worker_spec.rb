# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('app/workers/schedule_course_updates_worker')

describe ScheduleCourseUpdatesWorker do
  let(:course) { create(:course) }

  it 'starts a ScheduleCourseUpdates service' do
    expect(ScheduleCourseUpdates).to receive(:new)
    described_class.set(queue: 'constant_update').perform_async
  end
end
