# frozen_string_literal: true

require 'rails_helper'

describe PurgeCourseTimeslicesWorker do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:course) do
    create(:course, slug: 'School/Old_(Term)', start: 2.years.ago, end: 1.year.ago,
                    flags: { purgeable: true })
  end
  let(:cleaner) { instance_double(TimesliceCleaner, delete_timeslices_for_purge: nil) }

  before do
    allow(TimesliceCleaner).to receive(:new).with(course).and_return(cleaner)
    allow(StoreTimesliceEditCounts).to receive(:new)
  end

  def perform
    described_class.new.perform(course.id)
    course.reload
  end

  context 'when the course can be purged' do
    before { perform }

    it 'stores the edit counts' do
      expect(StoreTimesliceEditCounts).to have_received(:new).with(course)
    end

    it 'deletes the timeslices' do
      expect(cleaner).to have_received(:delete_timeslices_for_purge)
    end

    it 'marks the course as finalized instead of purgeable' do
      expect(course.finalized?).to be true
      expect(course.purgeable?).to be false
    end
  end

  context 'when the course fails a check' do
    before do
      course.update(needs_update: true)
      allow(Sentry).to receive(:capture_message)
      perform
    end

    it 'does not purge the course' do
      expect(StoreTimesliceEditCounts).not_to have_received(:new)
      expect(cleaner).not_to have_received(:delete_timeslices_for_purge)
      expect(course.purgeable?).to be true
    end

    it 'logs the failed checks' do
      expect(Sentry).to have_received(:capture_message)
        .with('Course purge skipped', hash_including(extra: hash_including(
          failed_checks: [:no_full_update_pending]
        )))
    end
  end

  it 'does not delete anything if storing the edit counts fails' do
    allow(StoreTimesliceEditCounts).to receive(:new).and_raise(ActiveRecord::RecordInvalid)
    expect { described_class.new.perform(course.id) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(cleaner).not_to have_received(:delete_timeslices_for_purge)
    expect(course.reload.finalized?).to be false
  end

  describe '.failed_checks' do
    it 'is empty for a purgeable course that passes every check' do
      expect(described_class.failed_checks(course)).to eq([])
    end

    it 'includes the flag checks' do
      course.update(flags: { finalized: true })
      expect(described_class.failed_checks(course)).to eq(%i[purgeable not_finalized])
    end
  end
end
