# frozen_string_literal: true

require 'rails_helper'

describe SystemStatUpdateWorker do
  let(:wiki) { Wiki.default_wiki }

  # Create a currently running, non-private course with stats
  let!(:active_course) do
    create(:course,
           start: 1.month.ago,
           end: 1.month.from_now,
           slug: 'School/Active_(term)',
           revision_count: 500,
           view_sum: 10_000,
           article_count: 50,
           new_article_count: 10,
           character_sum: 100_000,
           home_wiki_id: wiki.id,
           private: false)
  end

  # Create an archived course
  let!(:archived_course) do
    create(:course,
           start: 2.years.ago,
           end: 1.year.ago,
           slug: 'School/Archived_(term)',
           revision_count: 300,
           view_sum: 5_000,
           article_count: 30,
           new_article_count: 5,
           character_sum: 50_000,
           home_wiki_id: wiki.id,
           private: false)
  end

  # Private course — should be excluded from all counts
  let!(:private_course) do
    create(:course,
           start: 1.month.ago,
           end: 1.month.from_now,
           slug: 'School/Private_(term)',
           revision_count: 999,
           view_sum: 999,
           home_wiki_id: wiki.id,
           private: true)
  end

  # Create an instructor for the active course
  let!(:instructor) do
    user = create(:user, username: 'Instructor1')
    create(:courses_user, course: active_course, user: user,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    user
  end

  # Create a student who registered during the course (new editor)
  let!(:new_editor) do
    user = create(:user, username: 'NewEditor1',
                         registered_at: active_course.start + 1.week)
    create(:courses_user, course: active_course, user: user,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    user
  end

  # Create a student who registered 30 days before course start
  # (within 60-day pre-window, but NOT during the course itself)
  let!(:preregistered_editor) do
    user = create(:user, username: 'PreregEditor1',
                         registered_at: active_course.start - 30.days)
    create(:courses_user, course: active_course, user: user,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    user
  end

  # Create a student who registered before the 60-day window (NOT a new editor)
  let!(:existing_editor) do
    user = create(:user, username: 'ExistingEditor1',
                         registered_at: active_course.start - 1.year)
    create(:courses_user, course: active_course, user: user,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    user
  end

  describe '#perform' do
    before do
      allow(Features).to receive(:wiki_ed?).and_return(false)
    end

    it 'does not run on Wiki Ed dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(true)
      expect { described_class.new.perform }.not_to change(SystemStat, :count)
    end

    it 'creates a system stat record for today' do
      expect { described_class.new.perform }.to change(SystemStat, :count).by(1)
      stat = SystemStat.find_by(snapshot_date: Time.zone.today)
      expect(stat).to be_present
    end

    it 'computes correct aggregate totals (excludes private courses)' do
      described_class.new.perform
      stat = SystemStat.find_by(snapshot_date: Time.zone.today)

      # Only active_course + archived_course (private excluded)
      expect(stat.total_edits).to eq(800)          # 500 + 300
      expect(stat.total_article_views).to eq(15_000) # 10000 + 5000
      expect(stat.total_articles_improved).to eq(80)  # 50 + 30
      expect(stat.total_articles_created).to eq(15)   # 10 + 5
      expect(stat.total_characters_added).to eq(150_000) # 100000 + 50000
    end

    it 'computes active and archived program counts' do
      described_class.new.perform
      stat = SystemStat.find_by(snapshot_date: Time.zone.today)

      expect(stat.active_programs_count).to eq(1)   # only active_course
      expect(stat.archived_programs_count).to eq(1)  # only archived_course
    end

    it 'counts new editors (original: registered during course)' do
      described_class.new.perform
      stat = SystemStat.find_by(snapshot_date: Time.zone.today)

      # new_editor registered during course → counted
      # preregistered_editor registered 30 days before start → NOT counted (outside course window)
      # existing_editor registered 1 year before → NOT counted
      expect(stat.new_editors_count).to eq(1)
    end

    it 'counts new editors with preregistration (60-day window)' do
      described_class.new.perform
      stat = SystemStat.find_by(snapshot_date: Time.zone.today)

      # new_editor registered during course → counted
      # preregistered_editor registered 30 days before start → counted (within 60-day window)
      # existing_editor registered 1 year before → NOT counted
      expect(stat.new_editors_count_with_preregistration).to eq(2)
    end

    it 'counts active facilitators' do
      described_class.new.perform
      stat = SystemStat.find_by(snapshot_date: Time.zone.today)

      expect(stat.active_facilitators_count).to eq(1)
    end

    it 'generates wiki_stats breakdown' do
      described_class.new.perform
      stat = SystemStat.find_by(snapshot_date: Time.zone.today)

      expect(stat.wiki_stats).to be_a(Hash)
      expect(stat.wiki_stats.keys).to include(wiki.domain)
      wiki_entry = stat.wiki_stats[wiki.domain]
      expect(wiki_entry['edits']).to eq(800)
      expect(wiki_entry['programs']).to eq(2)
      expect(wiki_entry['new_editors_with_preregistration']).to eq(2)
    end

    it 'upserts when run twice on the same day' do
      described_class.new.perform
      described_class.new.perform
      expect(SystemStat.where(snapshot_date: Time.zone.today).count).to eq(1)
    end
  end
end
