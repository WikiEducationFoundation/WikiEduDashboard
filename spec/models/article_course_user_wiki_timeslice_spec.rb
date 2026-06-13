# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_user_wiki_timeslices
#
#  id               :bigint           not null, primary key
#  course_id        :integer          not null
#  wiki_id          :integer          not null
#  article_id       :integer          not null
#  user_id          :integer          not null
#  start            :datetime
#  end              :datetime
#  character_sum    :integer          default(0)
#  references_count :integer          default(0)
#  revision_count   :integer          default(0)
#  new_article      :boolean          default(FALSE)
#  tracked          :boolean          default(TRUE)
#  first_revision   :datetime
#  stats            :text
#  needs_update     :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

describe ArticleCourseUserWikiTimeslice, type: :model do
  let(:ts_start) { '2021-01-24'.to_datetime }
  let(:ts_end) { ts_start + 1.day }
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, start: ts_start, end: ts_start + 7.days) }
  let(:user1) { create(:user, username: 'User1') }
  let(:user2) { create(:user, username: 'User2') }
  let(:article1) { create(:article, wiki:) }
  let(:article2) { create(:article, title: 'SecondArticle', wiki:) }

  describe '.periods_for_articles' do
    before do
      create(:article_course_user_wiki_timeslice,
             course:, wiki:, article: article1, user: user1,
             start: ts_start, end: ts_end)
      create(:article_course_user_wiki_timeslice,
             course:, wiki:, article: article1, user: user1,
             start: ts_start + 1.day, end: ts_start + 2.days)
      create(:article_course_user_wiki_timeslice,
             course:, wiki:, article: article2, user: user1,
             start: ts_start, end: ts_end)
    end

    it 'returns distinct (start, end) pairs for the given articles' do
      pairs = described_class.periods_for_articles(course, wiki, [article1.id])
      expect(pairs).to contain_exactly(
        [ts_start, ts_end],
        [ts_start + 1.day, ts_start + 2.days]
      )
    end

    it 'excludes rows for other articles' do
      pairs = described_class.periods_for_articles(course, wiki, [article2.id])
      expect(pairs).to contain_exactly([ts_start, ts_end])
    end

    it 'deduplicates periods when multiple users have rows for the same period' do
      create(:article_course_user_wiki_timeslice,
             course:, wiki:, article: article1, user: user2,
             start: ts_start, end: ts_end)
      pairs = described_class.periods_for_articles(course, wiki, [article1.id])
      expect(pairs.count { |(s, _)| s == ts_start }).to eq(1)
    end
  end

  describe '.users_for_articles_in_period' do
    before do
      create(:article_course_user_wiki_timeslice,
             course:, wiki:, article: article1, user: user1,
             start: ts_start, end: ts_end)
      create(:article_course_user_wiki_timeslice,
             course:, wiki:, article: article1, user: user2,
             start: ts_start + 1.day, end: ts_start + 2.days)
    end

    it 'returns users with rows for the given articles and period start' do
      users = described_class.users_for_articles_in_period(course, wiki, [article1.id], ts_start)
      expect(users).to contain_exactly(user1)
    end

    it 'excludes users whose rows are in a different period' do
      users = described_class.users_for_articles_in_period(
        course, wiki, [article1.id], ts_start + 1.day
      )
      expect(users).to contain_exactly(user2)
    end
  end

  describe '.bulk_upsert_from_revisions' do
    def live_revision(article:, user:, characters: 100, mw_rev_id: rand(100_000),
                      new_article: false, error: false, date: ts_start + 1.hour)
      build(:revision_on_memory,
            article_id: article.id, user_id: user.id, wiki_id: wiki.id,
            mw_rev_id:, characters:, new_article:, error:, date:,
            deleted: false, system: false,
            features: { 'num_ref' => 2 },
            features_previous: { 'num_ref' => 1 })
    end

    context 'with a single live revision' do
      it 'creates an ACUWT row with correct stats' do
        rev = live_revision(article: article1, user: user1, characters: 200, new_article: true)
        described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end, [rev])

        row = described_class.find_by(course:, wiki:, article: article1, user: user1,
start: ts_start)
        expect(row).to be_present
        expect(row.revision_count).to eq(1)
        expect(row.character_sum).to eq(200)
        expect(row.new_article).to eq(true)
        expect(row.first_revision).to be_within(1.second).of(rev.date)
        expect(row.needs_update).to eq(false)
      end

      it 'creates separate rows for each (article, user) combination' do
        rev1 = live_revision(article: article1, user: user1)
        rev2 = live_revision(article: article1, user: user2)
        rev3 = live_revision(article: article2, user: user1)
        described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end,
                                                   [rev1, rev2, rev3])

        expect(described_class.where(course:, wiki:, start: ts_start).count).to eq(3)
      end
    end

    context 'with deleted and system revisions' do
      it 'excludes deleted revisions from revision_count and character_sum' do
        live = live_revision(article: article1, user: user1, characters: 100)
        deleted = build(:revision_on_memory,
                        article_id: article1.id, user_id: user1.id, wiki_id: wiki.id,
                        mw_rev_id: 99999, characters: 500, deleted: true, system: false,
                        date: ts_start + 2.hours)
        described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end, [live, deleted])

        row = described_class.find_by(course:, wiki:, article: article1, user: user1,
start: ts_start)
        expect(row.revision_count).to eq(1)
        expect(row.character_sum).to eq(100)
      end

      it 'sets new_article from any revision, including deleted ones' do
        deleted_new = build(:revision_on_memory,
                            article_id: article1.id, user_id: user1.id, wiki_id: wiki.id,
                            mw_rev_id: 11111, characters: 0, deleted: true, system: false,
                            new_article: true, date: ts_start + 1.hour)
        live = live_revision(article: article1, user: user1, new_article: false)
        described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end,
                                                   [deleted_new, live])

        row = described_class.find_by(course:, wiki:, article: article1, user: user1,
start: ts_start)
        expect(row.new_article).to eq(true)
      end
    end

    context 'with negative character changes' do
      it 'treats negative characters as zero in character_sum' do
        rev = live_revision(article: article1, user: user1, characters: -50)
        described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end, [rev])

        row = described_class.find_by(course:, wiki:, article: article1, user: user1,
start: ts_start)
        expect(row.character_sum).to eq(0)
      end
    end

    context 'when a revision has an error flag' do
      it 'sets needs_update: true on the row' do
        rev = live_revision(article: article1, user: user1, error: true)
        described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end, [rev])

        row = described_class.find_by(course:, wiki:, article: article1, user: user1,
start: ts_start)
        expect(row.needs_update).to eq(true)
      end

      it 'clears needs_update when a subsequent upsert has no errors' do
        create(:article_course_user_wiki_timeslice,
               course:, wiki:, article: article1, user: user1,
               start: ts_start, end: ts_end, needs_update: true)
        rev = live_revision(article: article1, user: user1, error: false)
        described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end, [rev])

        row = described_class.find_by(course:, wiki:, article: article1, user: user1,
start: ts_start)
        expect(row.needs_update).to eq(false)
      end
    end

    context 'when revisions have nil article_id or user_id' do
      it 'skips those revisions' do
        no_article = build(:revision_on_memory, article_id: nil, user_id: user1.id,
                           wiki_id: wiki.id, mw_rev_id: 11111)
        no_user = build(:revision_on_memory, article_id: article1.id, user_id: nil,
                        wiki_id: wiki.id, mw_rev_id: 22222)
        described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end,
                                                   [no_article, no_user])

        expect(described_class.where(course:, wiki:, start: ts_start).count).to eq(0)
      end
    end

    context 'when the revision list is empty after filtering' do
      it 'returns without writing any rows' do
        expect do
          described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end, [])
        end.not_to change(described_class, :count)
      end
    end

    context 'when a row for the same (course, wiki, article, user, start) already exists' do
      it 'updates stats on the existing row rather than creating a duplicate' do
        create(:article_course_user_wiki_timeslice,
               course:, wiki:, article: article1, user: user1,
               start: ts_start, end: ts_end, revision_count: 1, character_sum: 50)
        rev = live_revision(article: article1, user: user1, characters: 200)
        described_class.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end, [rev])

        expect(described_class.where(course:, wiki:, article: article1,
                                     user: user1, start: ts_start).count).to eq(1)
        expect(described_class.find_by(course:, wiki:, article: article1,
                                       user: user1, start: ts_start).character_sum).to eq(200)
      end
    end
  end
end
