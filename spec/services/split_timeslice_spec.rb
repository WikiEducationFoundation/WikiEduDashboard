# frozen_string_literal: true

require 'rails_helper'

describe SplitTimeslice do
  let(:start) { '2025-08-26 17:00:00'.to_datetime }
  let(:end_date) { '2025-08-27 17:00:00'.to_datetime }
  # Use basic_course to not override dates
  let(:course) { create(:basic_course, start:, end: end_date) }
  let(:wiki) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:user) { create(:user, username: 'Rizall 91202') }
  let(:splitter) { described_class.new(course) }

  before do
    stub_wiki_validation
    course.wikis << wiki
    course.campaigns << Campaign.first
    JoinCourse.new(course:, user:, role: 0)
  end

  describe '#maybe_split' do
    let(:rev1) { build(:revision_on_memory, scoped: true) }
    let(:rev2) { build(:revision_on_memory, scoped: true) }
    let(:rev3) { build(:revision_on_memory, scoped: true) }
    let(:revisions) { { wiki => { revisions: [rev1, rev2, rev3] } } }

    context 'when revisions exceed threshold' do
      before do
        stub_const('SplitTimeslice::REVISION_THRESHOLD', 2)
        TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
      end

      it 'splits the timeslice' do
        expect(course.course_wiki_timeslices.count).to eq(2)
        split, dates = splitter.maybe_split(wiki, course.start, course.start + 1.day, revisions)
        expect(split).to eq(true)
        expect(dates[0]).to eq(course.start)
        expect(dates[1]).to eq(course.start + 12.hours)
        expect(dates[2]).to eq(course.start + 1.day)
        expect(dates).to all(be_a(Time))
        # timeslice was deleted
        expect(CourseWikiTimeslice.where(course:, wiki:, start:,
                                         end: start + 1.day)).to be_empty
      end

      it 'splits the timeslice even when odd seconds' do
        expect(course.course_wiki_timeslices.count).to eq(2)
        split, dates = splitter.maybe_split(wiki, course.start, course.start + 675.seconds,
                                            revisions)
        expect(split).to eq(true)
        expect(dates[0]).to eq(course.start)
        expect(dates[1]).to eq(course.start + 338.seconds)
        expect(dates[2]).to eq(course.start + 675.seconds)
        expect(dates).to all(be_a(Time))
      end
    end

    context 'when revisions do not exceed threshold' do
      before do
        TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
      end

      it 'does not split the timeslice' do
        expect(course.course_wiki_timeslices.count).to eq(2)
        split, dates = splitter.maybe_split(wiki, course.start, course.start + 1.day, revisions)
        expect(split).to eq(false)
        expect(dates).to be_empty
        expect(course.course_wiki_timeslices.count).to eq(2)
      end
    end
  end
end
