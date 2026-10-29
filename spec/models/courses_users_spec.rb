# frozen_string_literal: true
# == Schema Information
#
# Table name: courses_users
#
#  id                     :integer          not null, primary key
#  created_at             :datetime
#  updated_at             :datetime
#  course_id              :integer
#  user_id                :integer
#  character_sum_ms       :integer          default(0)
#  character_sum_us       :integer          default(0)
#  revision_count         :integer          default(0)
#  assigned_article_title :string(255)
#  role                   :integer          default(0)
#  recent_revisions       :integer          default(0)
#  character_sum_draft    :integer          default(0)
#  real_name              :string(255)
#  role_description       :string(255)
#  total_uploads          :integer
#  references_count       :integer          default(0)
#

require 'rails_helper'

describe CoursesUsers, type: :model do
  before { stub_wiki_validation }

  describe '.update_all_caches_from_timeslices' do
    let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:user) { create(:user, id: 1) }
    let(:course) { create(:course, start: 1.month.ago, end: 1.month.from_now) }

    before do
      # Make a CoursesUser record
      create(:courses_user, id: 456, course:, user:)
    end

    it 'updates data for course-user relationships' do
      # Run a cache update without any timeslices.
      described_class.update_all_caches_from_timeslices(described_class.all)

      # Add two timeslices.
      create(:course_user_wiki_timeslice,
             course:,
             user:,
             wiki: enwiki,
             start: 10.days.ago,
             end: 9.days.ago,
             character_sum_ms: 9000,
             character_sum_us: 500,
             character_sum_draft: 400,
             references_count: 4,
             revision_count: 5)

      create(:course_user_wiki_timeslice,
             course:,
             user:,
             wiki: enwiki,
             start: 9.days.ago,
             end: 8.days.ago,
             character_sum_ms: 10,
             character_sum_us: 20,
             character_sum_draft: 30,
             references_count: 3,
             revision_count: 1)

      # Empty timeslice, which should not count towards stats.
      create(:course_user_wiki_timeslice,
             course:,
             user:,
             wiki: enwiki,
             start: 20.days.ago,
             end: 19.days.ago,
             character_sum_ms: 0,
             character_sum_us: 0,
             character_sum_draft: 0,
             references_count: 0,
             revision_count: 0)

      # Create a common upload for the user
      create(:commons_upload, user:, uploaded_at: 1.week.ago)

      # Run the cache update again with an existing revision.
      described_class.update_all_caches_from_timeslices(described_class.all)

      # Fetch the updated CoursesUsers entry
      course_user = described_class.first

      expect(course_user.character_sum_ms).to eq(9010)
      expect(course_user.character_sum_us).to eq(520)
      expect(course_user.character_sum_draft).to eq(430)
      # count real number of uploads for user
      expect(course_user.total_uploads).to eq(1)
      expect(course_user.references_count).to eq(7)
      expect(course_user.revision_count).to eq(6)
    end

    context 'with timeslices for a wiki excluded from word counts' do
      let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }

      before do
        create(:course_user_wiki_timeslice,
               course:,
               user:,
               wiki: enwiki,
               start: 10.days.ago,
               end: 9.days.ago,
               character_sum_ms: 9000,
               character_sum_us: 500,
               character_sum_draft: 400,
               references_count: 4,
               revision_count: 5)

        create(:course_user_wiki_timeslice,
               course:,
               user:,
               wiki: wikidata,
               start: 9.days.ago,
               end: 8.days.ago,
               character_sum_ms: 50_000,
               character_sum_us: 6000,
               character_sum_draft: 7000,
               references_count: 0,
               revision_count: 3)

        described_class.update_all_caches_from_timeslices(described_class.all)
      end

      it 'leaves the wikidata characters out of the character sums' do
        course_user = described_class.first
        expect(course_user.character_sum_ms).to eq(9000)
        expect(course_user.character_sum_us).to eq(500)
        expect(course_user.character_sum_draft).to eq(400)
      end

      it 'still counts the wikidata revisions in revision_count' do
        expect(described_class.first.revision_count).to eq(8)
      end
    end

    it 'looks up the excluded wiki ids once for the batch, not once per user' do
      create(:courses_user, course:, user: create(:user, id: 2, username: 'Second'))
      expect(WordCount).to receive(:excluded_wiki_ids).once.and_call_original

      described_class.update_all_caches_from_timeslices(described_class.all)
    end

    context 'with several students' do
      let(:second_user) { create(:user, id: 2, username: 'Second') }

      before do
        create(:courses_user, course:, user: second_user)
        create(:assignment, course:, user:, article_id: 1, article_title: 'First_title')
        create(:assignment, course:, user:, article_id: 2, article_title: 'Second_title')
        create(:commons_upload, user:, uploaded_at: 1.week.ago)
        create(:commons_upload, user: second_user, uploaded_at: 1.week.ago)
      end

      def queries_matching(pattern)
        statements = []
        callback = ->(event) { statements << event.payload[:sql] }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          described_class.update_all_caches_from_timeslices(described_class.all)
        end
        statements.grep(pattern).count
      end

      it 'sets uploads and the first assigned article title for each user' do
        described_class.update_all_caches_from_timeslices(described_class.all)

        expect(described_class.find_by(user:).total_uploads).to eq(1)
        expect(described_class.find_by(user:).assigned_article_title).to eq('First_title')
        expect(described_class.find_by(user: second_user).total_uploads).to eq(1)
        expect(described_class.find_by(user: second_user).assigned_article_title).to eq('')
      end

      it 'queries uploads and assignments once per course, not once per user' do
        expect(queries_matching(/FROM `commons_uploads`/)).to eq(1)
        expect(queries_matching(/FROM `assignments`/)).to eq(1)
      end
    end

    # Regression: course.courses_users shares one in-memory Course across the whole
    # batch (and across repeated calls on that instance), which is what
    # UpdateCourseStats#update_caches passes. described_class.all above doesn't hit this,
    # since each record there loads its own #course.
    it 'picks up a new upload on a second update_all_caches_from_timeslices call' do
      create(:commons_upload, id: 1, user:, uploaded_at: 1.week.ago)
      described_class.update_all_caches_from_timeslices(course.courses_users)
      expect(described_class.find_by(user:).total_uploads).to eq(1)

      create(:commons_upload, id: 2, user:, uploaded_at: 1.week.ago)
      course.reload
      described_class.update_all_caches_from_timeslices(course.courses_users)
      expect(described_class.find_by(user:).total_uploads).to eq(2)
    end

    it 'keeps uploads and assigned titles separate per course in a mixed-course batch' do
      other_course = create(:course, id: 999, slug: 'none/Other_(course)',
                            start: 1.month.ago, end: 1.month.from_now)
      other_user = create(:user, id: 2, username: 'OtherCourseUser')
      create(:courses_user, id: 457, course: other_course, user: other_user)
      create(:commons_upload, user:, uploaded_at: 1.week.ago)
      create(:assignment, course:, user:, article_id: 1, article_title: 'This_course_title')
      create(:assignment, course: other_course, user: other_user, article_id: 2,
             article_title: 'Other_course_title')

      described_class.update_all_caches_from_timeslices(described_class.all)

      expect(described_class.find_by(user:).total_uploads).to eq(1)
      expect(described_class.find_by(user:).assigned_article_title).to eq('This_course_title')
      expect(described_class.find_by(user: other_user).total_uploads).to eq(0)
      expect(described_class.find_by(user: other_user).assigned_article_title)
        .to eq('Other_course_title')
    end
  end

  describe '#contribution_url' do
    let(:en_wiki_course) { create(:course) }
    let(:es_wiktionary) { create(:wiki, language: 'es', project: 'wiktionary') }
    let(:es_wiktionary_course) { create(:course, home_wiki_id: es_wiktionary.id, slug: 'foo/es') }
    let(:user) { create(:user, username: 'Ragesoss') }

    it 'links the the contribution page of the home_wiki for the course' do
      courses_user = create(:courses_user, user_id: user.id, course_id: en_wiki_course.id)
      expect(courses_user.contribution_url).to eq('https://en.wikipedia.org/wiki/Special:Contributions/Ragesoss')

      courses_user2 = create(:courses_user, user_id: user.id, course_id: es_wiktionary_course.id)
      expect(courses_user2.contribution_url).to eq('https://es.wiktionary.org/wiki/Special:Contributions/Ragesoss')
    end

    context 'when the username ends with a question mark' do
      let(:user) { create(:user, username: 'Ahneechanges?') }

      it 'correctly encodes the url' do
        courses_user = create(:courses_user, user_id: user.id, course_id: en_wiki_course.id)
        expect(courses_user.contribution_url).to eq('https://en.wikipedia.org/wiki/Special:Contributions/Ahneechanges%3F')
      end
    end

    context 'when the username has spaces in it' do
      let(:user) { create(:user, username: 'Alaura Hopper') }

      it 'converts spaces to underscores to match mediawiki convention' do
        courses_user = create(:courses_user, user_id: user.id, course_id: en_wiki_course.id)
        expect(courses_user.contribution_url).to eq('https://en.wikipedia.org/wiki/Special:Contributions/Alaura_Hopper')
      end
    end
  end

  context 'when a nonstudent user is an admin and a greeter' do
    let(:user) { create(:user, permissions: 1, greeter: true) }
    let(:course) { create(:course) }
    let(:subject) do
      create(:courses_user, user_id: user.id, course_id: course.id,
                            role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    end

    it '#content_expert is true' do
      expect(subject.content_expert).to eq(true)
    end

    it '#program_manager is false' do
      expect(subject.program_manager).to eq(false)
    end
  end

  context 'when a nonstudent user is an admin but not a greeter' do
    let(:user) { create(:user, permissions: 1, greeter: false) }
    let(:course) { create(:course) }
    let(:subject) do
      create(:courses_user, user_id: user.id, course_id: course.id,
                            role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    end

    it '#content_expert is true' do
      expect(subject.content_expert).to eq(false)
    end

    it '#program_manager is false' do
      expect(subject.program_manager).to eq(true)
    end
  end
end
