# frozen_string_literal: true

require 'rails_helper'

describe UpdateCourseStats do
  let(:course) { create(:course, flags: flags) }
  let(:subject) { described_class.new(course) }

  context 'when debugging is not enabled' do
    let(:flags) { nil }

    it 'posts no Sentry logs' do
      expect(Raven).not_to receive(:capture_message)
      subject
    end
  end

  context 'when the course has :needs_update set "true"' do
    let(:course) { create(:course, needs_update: true) }

    it 'updates it to "false"' do
      subject
      expect(course.reload.needs_update).to eq(false)
    end
  end

  context 'when :debug_updates flag is set' do
    let(:flags) { { debug_updates: true } }

    it 'posts debug info to Sentry' do
      expect(Raven).to receive(:capture_message).at_least(6).times.and_call_original
      subject
    end
  end
end
