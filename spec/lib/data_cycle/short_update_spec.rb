# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/short_update"

describe ShortUpdate do
  describe 'on initialization' do
    before do
      create(:editathon, start: 1.day.ago, end: 2.hours.from_now,
                         slug: 'ArtFeminism/Test_Editathon')
    end

    it 'calls the revisions and articles updates on courses currently taking place' do
      expect(UpdateCourseRevisions).to receive(:new)
      expect(Raven).to receive(:capture_message).and_call_original
      update = ShortUpdate.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/Importing revisions and articles/).any?).to eq(true)
    end

    it 'reports logs to sentry even when it errors out' do
      allow(Raven).to receive(:capture_message)
      expect(UpdateCourseRevisions).to receive(:new)
        .and_raise(StandardError)
      expect { ShortUpdate.new }.to raise_error(StandardError)
      expect(Raven).to have_received(:capture_message)
    end
  end
end
