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
#  mw_rev_count         :integer          default(0)
#
require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe CourseWikiTimeslice, type: :model do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:array_revisions) { [] }
  let(:article) { create(:article, id: 1, namespace: 0) }
  let(:article_id) { article.id }
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

    array_revisions << build(:revision_on_memory, article_id:, user_id: 1, date: start,
scoped: true)
    array_revisions << build(:revision_on_memory, article_id:, user_id: 1, date: start + 2.hours,
scoped: true)
    array_revisions << build(:revision_on_memory, article_id:, user_id: 2, date: start + 3.hours,
scoped: false)
    array_revisions << build(:revision_on_memory, article_id:, user_id: 2, date: start + 3.hours,
                             system: true, scoped: true)
    array_revisions << build(:revision_on_memory, article_id:, deleted: true, user_id: 1,
                             date: start + 8.hours, scoped: true)
  end

  describe '.update_course_wiki_timeslices' do
    before do
      TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
    end

    it 'updates the right course wiki timeslice based on the revisions' do
      course_wiki_timeslice_0 = described_class.find_by(course:, wiki:, start:)

      expect(course_wiki_timeslice_0.revision_count).to eq(0)

      start_period = start.strftime('%Y%m%d%H%M%S')
      end_period = (start + 1.day - 1.second).strftime('%Y%m%d%H%M%S')
      revisions = { start: start_period, end: end_period, revisions: array_revisions }
      described_class.update_course_wiki_timeslices(course, wiki, revisions)

      course_wiki_timeslice_0 = described_class.find_by(course:, wiki:, start:)

      expect(course_wiki_timeslice_0.revision_count).to eq(2)
    end

    it 'sets mw_rev_count to the non-system count, including deleted revs' do
      start_period = start.strftime('%Y%m%d%H%M%S')
      end_period = (start + 1.day - 1.second).strftime('%Y%m%d%H%M%S')
      revisions = { start: start_period, end: end_period, revisions: array_revisions }
      described_class.update_course_wiki_timeslices(course, wiki, revisions)

      # First slice has 2 normal + 1 non-scoped + 1 system + 1 deleted =
      # 3 scoped non-system revs.
      # revision_count excludes the deleted one and the non-scoped one (2);
      # mw_rev_count keeps the deleted one (3).
      slice_0 = described_class.find_by(course:, wiki:, start:)
      expect(slice_0.revision_count).to eq(2)
      expect(slice_0.mw_rev_count).to eq(3)
    end

    it 'sends a Sentry error when multiple timeslices are matched' do
      start_period = start.strftime('%Y%m%d%H%M%S')
      end_period = (start + 55.hours).strftime('%Y%m%d%H%M%S')

      expect(Sentry).to receive(:capture_message)
        .with("Multiple timeslices matched for course #{course.slug}",
              level: 'error',
              extra: hash_including(course_id: course.id, wiki_id: wiki.id,
                                    start: start_period, end: end_period))

      revisions = { start: start_period, end: end_period, revisions: array_revisions }
      described_class.update_course_wiki_timeslices(course, wiki, revisions)
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
        expect(course_wiki_timeslice.revision_count).to eq(2)
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

      it 'mw_rev_count ignores tracked status and deleted, excludes system and non-scoped' do
        # Even when the only article is untracked, mw_rev_count counts every
        # non-system rev — it must mirror what CourseRevisionUpdater#new_revisions?
        # computes from the live fetched revisions.
        ArticlesCourses.find(1).update(tracked: 0)

        course_wiki_timeslice = described_class.find_by(course:, wiki:, start:)
        course_wiki_timeslice.update_cache_from_revisions array_revisions

        expect(course_wiki_timeslice.revision_count).to eq(0)
        # 2 normal + 1 deleted, minus the 1 system and the 1 non-scoped = 3
        expect(course_wiki_timeslice.mw_rev_count).to eq(3)
      end
    end

    context 'if revision with error' do
      before do
        TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
        array_revisions << build(:revision_on_memory, article_id:, user_id: 1,
                                 date: start + 1.hour, scoped: true,
                                 error: true) # add revision with error
      end

      it 'keeps needs_update flag if revisions with error' do
        course_wiki_timeslice = described_class.find_by(course:, wiki:, start:)
        expect(course_wiki_timeslice.needs_update).to eq(false)
        course_wiki_timeslice.update_cache_from_revisions array_revisions
        course_wiki_timeslice.reload

        expect(course_wiki_timeslice.needs_update).to eq(true)
      end
    end

    context 'when course.use_acuwt? is true' do
      let(:timeslice_end) { send(:end) }

      before do
        course.add_flag(key: :use_acuwt)
        TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
        create(:article_course_user_wiki_timeslice, course:, wiki:, article:, user_id: 1,
               start:, end: timeslice_end, character_sum: 500, references_count: 3)
        create(:article_course_user_wiki_timeslice, course:, wiki:, article:, user_id: 2,
               start:, end: timeslice_end, character_sum: 200, references_count: 1)
      end

      it 'computes character_sum and references_count from ACUWT for student mainspace articles' do
        course_wiki_timeslice = described_class.find_by(course:, wiki:, start:)
        course_wiki_timeslice.update_cache_from_revisions(array_revisions)

        expect(course_wiki_timeslice.character_sum).to eq(700)
        expect(course_wiki_timeslice.references_count).to eq(4)
      end

      context 'when a student also has ACUWT for a non-mainspace article' do
        let(:draft_article) { create(:article, namespace: Article::Namespaces::DRAFT) }

        before do
          create(:article_course_user_wiki_timeslice, course:, wiki:, article: draft_article,
                 user_id: 1, start:, end: timeslice_end, character_sum: 888, references_count: 10)
        end

        it 'excludes non-mainspace articles from character_sum and references_count' do
          course_wiki_timeslice = described_class.find_by(course:, wiki:, start:)
          course_wiki_timeslice.update_cache_from_revisions(array_revisions)

          expect(course_wiki_timeslice.character_sum).to eq(700)
          expect(course_wiki_timeslice.references_count).to eq(4)
        end
      end

      context 'when the article course is not tracked' do
        before do
          ArticlesCourses.find(1).update(tracked: false)
        end

        it 'excludes non-tracked articles from character_sum and references_count' do
          course_wiki_timeslice = described_class.find_by(course:, wiki:, start:)
          course_wiki_timeslice.update_cache_from_revisions(array_revisions)

          expect(course_wiki_timeslice.character_sum).to eq(0)
          expect(course_wiki_timeslice.references_count).to eq(0)
        end
      end
    end
  end
end
