# frozen_string_literal: true

# == Schema Information
#
# Table name: course_wiki_timeslices
#
#  id                   :bigint           not null, primary key
#  course_id            :integer          not null
#  wiki_id              :integer          not null
#  start                :datetime
#  end                  :datetime
#  character_sum        :integer          default(0)
#  references_count     :integer          default(0)
#  revision_count       :integer          default(0)
#  stats                :text(65535)
#  last_mw_rev_datetime :datetime
#  needs_update         :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe CourseWikiTimeslice, type: :model do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:array_revisions) { [] }
  let(:article) { create(:article, id: 1, namespace: 0) }
  let(:course) do
    create(:course, start: Time.zone.today - 1.month, end: Time.zone.today + 1.month)
  end
  let(:start) { 10.days.ago.beginning_of_day }
  let(:end) { 9.days.ago.beginning_of_day }

  before do
    stub_const('TimesliceManager::TIMESLICE_DURATION', 86400)

    create(:user, id: 1, username: 'Ragesoss')
    create(:user, id: 2, username: 'Gatoespecie')

    create(:articles_course, id: 1, article_id: 1, course:)

    create(:courses_user, id: 1, course:, user_id: 1)
    create(:courses_user, id: 2, course:, user_id: 2)
    create(:courses_user, id: 3, course:, user_id: 2,
role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

    create(:course_user_wiki_timeslice,
           course:,
           user_id: 1,
           wiki:,
           start:,
           end:,
           character_sum_ms: 9000,
           character_sum_us: 500,
           character_sum_draft: 400,
           references_count: 4,
           revision_count: 5)
    create(:course_user_wiki_timeslice,
           course:,
           user_id: 2,
           wiki:,
           start:,
           end:,
           character_sum_ms: 10,
           character_sum_us: 20,
           character_sum_draft: 30,
           references_count: 3,
           revision_count: 1)
    # Course user wiki timeslice for non-student
    create(:course_user_wiki_timeslice,
           course:,
           user_id: 3,
           wiki:,
           start:,
           end:,
           character_sum_ms: 100,
           character_sum_us: 200,
           character_sum_draft: 330,
           references_count: 4,
           revision_count: 4)

    array_revisions << build(:revision, article:, user_id: 1, date: start, scoped: true)
    array_revisions << build(:revision, article:, user_id: 1, date: start + 2.hours, scoped: true)
    array_revisions << build(:revision, article:, user_id: 2, date: start + 3.hours, scoped: true)
    array_revisions << build(:revision, article:, user_id: 2, date: start + 3.hours, system: true,
                             scoped: true)
    array_revisions << build(:revision, article:, deleted: true, user_id: 1, date: start + 8.hours,
                             scoped: true)
  end

  describe '.update_course_wiki_timeslices' do
    before do
      TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
      array_revisions << build(:revision, article:, user_id: 1, date: start + 26.hours,
                               scoped: true)
      array_revisions << build(:revision, article:, user_id: 1, date: start + 50.hours,
                               scoped: true)
      array_revisions << build(:revision, article:, user_id: 1, date: start + 51.hours,
                               scoped: true)
    end

    it 'updates the right course wiki timeslices based on the revisions' do
      course_wiki_timeslice_0 = described_class.find_by(course:, wiki:, start:)
      course_wiki_timeslice_1 = described_class.find_by(course:, wiki:, start: start + 1.day)
      course_wiki_timeslice_2 = described_class.find_by(course:, wiki:, start: start + 2.days)

      expect(course_wiki_timeslice_0.revision_count).to eq(0)
      expect(course_wiki_timeslice_1.revision_count).to eq(0)
      expect(course_wiki_timeslice_2.revision_count).to eq(0)

      start_period = start.strftime('%Y%m%d%H%M%S')
      end_period = (start + 55.hours).strftime('%Y%m%d%H%M%S')
      revisions = { start: start_period, end: end_period, revisions: array_revisions }
      described_class.update_course_wiki_timeslices(course, wiki, revisions)

      course_wiki_timeslice_0 = described_class.find_by(course:, wiki:, start:)
      course_wiki_timeslice_1 = described_class.find_by(course:, wiki:, start: start + 1.day)
      course_wiki_timeslice_2 = described_class.find_by(course:, wiki:, start: start + 2.days)

      expect(course_wiki_timeslice_0.revision_count).to eq(3)
      expect(course_wiki_timeslice_1.revision_count).to eq(1)
      expect(course_wiki_timeslice_2.revision_count).to eq(2)
    end
  end

  describe '#update_cache_from_revisions' do
    context 'if no revisions with errors' do
      before do
        TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
        described_class.find_by(course:, wiki:, start:).update(needs_update: true)
      end

      it 'caches revision data for students and remove needs_update flag' do
        course_wiki_timeslice = described_class.find_by(course:, wiki:, start:)
        expect(course_wiki_timeslice.needs_update).to eq(true)
        course_wiki_timeslice.update_cache_from_revisions array_revisions
        course_wiki_timeslice.reload

        expect(course_wiki_timeslice.character_sum).to eq(9010)
        expect(course_wiki_timeslice.references_count).to eq(7)
        expect(course_wiki_timeslice.revision_count).to eq(3)
        expect(course_wiki_timeslice.needs_update).to eq(false)
      end

      it 'revision count cache only considers tracked articles courses' do
        # Untrack articles courses record
        ArticlesCourses.find(1).update(tracked: 0)

        course_wiki_timeslice = described_class.find_by(course:, wiki:, start:)
        course_wiki_timeslice.update_cache_from_revisions array_revisions

        expect(course_wiki_timeslice.character_sum).to eq(9010)
        expect(course_wiki_timeslice.references_count).to eq(7)
        # Don't add any new revision count
        expect(course_wiki_timeslice.revision_count).to eq(0)
      end
    end

    context 'if revision with error' do
      before do
        TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
        array_revisions << build(:revision, article:, user_id: 1, date: start + 51.hours,
        scoped: true, ithenticate_id: 1) # add revision with error
      end

      it 'keeps needs_update flag if revisions with error' do
        course_wiki_timeslice = described_class.find_by(course:, wiki:, start:)
        expect(course_wiki_timeslice.needs_update).to eq(false)
        course_wiki_timeslice.update_cache_from_revisions array_revisions
        course_wiki_timeslice.reload

        expect(course_wiki_timeslice.needs_update).to eq(true)
      end
    end
  end
end
