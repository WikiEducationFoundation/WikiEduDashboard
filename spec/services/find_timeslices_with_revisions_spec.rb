# frozen_string_literal: true

require 'rails_helper'

describe FindTimeslicesWithRevisions do
  let(:course) do
    create(:basic_course, start: '2018-11-01 00:00:00', end: '2018-11-30 23:55:00')
  end
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:timeslices) { course.course_wiki_timeslices.where(wiki: enwiki).to_a }
  let(:service) { described_class.new(course, enwiki, timeslices) }

  before do
    JoinCourse.new(course:, user:, role: 0)
    TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([enwiki])
  end

  def stub_replica_rows(rows)
    allow_any_instance_of(Replica).to receive(:get_revisions_raw).and_return(rows)
  end

  def slice_start_days
    service.slice_starts.map { |start| start.strftime('%Y%m%d') }
  end

  it 'returns the start datetimes of timeslices containing revisions' do
    stub_replica_rows([{ 'rev_timestamp' => '20181105123456' },
                       { 'rev_timestamp' => '20181112080910' },
                       { 'rev_timestamp' => '20181112235959' }])
    expect(slice_start_days).to contain_exactly('20181105', '20181112')
  end

  it 'assigns a revision on a timeslice boundary to the later timeslice' do
    stub_replica_rows([{ 'rev_timestamp' => '20181112000000' }])
    expect(slice_start_days).to contain_exactly('20181112')
  end

  it 'returns an empty set when there are no revisions' do
    stub_replica_rows([])
    expect(service.slice_starts).to be_empty
  end

  it 'returns nil when the Replica query fails' do
    stub_replica_rows(nil)
    expect(service.slice_starts).to be_nil
  end

  it 'queries Replica once, over the whole timeslice range' do
    replica = instance_double(Replica)
    allow(Replica).to receive(:new).with(enwiki, nil).and_return(replica)
    expect(replica).to receive(:get_revisions_raw)
      .with(course.students, '20181101000000', '20181130235500')
      .once.and_return([])
    service
  end
end
