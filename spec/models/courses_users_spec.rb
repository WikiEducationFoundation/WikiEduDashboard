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

  describe '.update_all_caches' do
    let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }
    let(:user) { create(:user, username: 'User') }
    let(:course) { create(:course, start: '2015-01-01'.to_date, end: '2015-07-01'.to_date) }
    let(:article) { create(:article, title: 'Selfie') }
    let(:talk_page) { create(:article, title: 'Selfie', namespace: Article::Namespaces::TALK) }
    let(:sandbox) { create(:article, title: 'User/Selfie', namespace: Article::Namespaces::USER) }
    let(:draft) { create(:article, title: 'Selfie', namespace: Article::Namespaces::DRAFT) }
    let(:courses_user) do
      create(:courses_user,
             course:,
             user:,
             assigned_article_title: 'Selfie',
             real_name: 'John Smith')
    end

    before do
      # Add a user, a course, an article, and a revision.
      create(:revision,
             user:,
             article:,
             date: '2015-03-01'.to_date,
             characters: 9000,
             features: {
               refs_tags_key => 22
             },
             features_previous: {
               refs_tags_key => 17
             })

      # Assign the article to the user.
      create(:assignment,
             course:,
             user:,
             article:,
             article_title: 'Selfie')

      # Make an article-course.
      create(:articles_course,
             article:,
             course:)

      # Add a talk page, sandbox and draft edits
      create(:revision,
             user:,
             article: talk_page,
             date: '2015-03-01'.to_date,
             characters: 500)
      create(:revision,
             user:,
             article: sandbox,
             date: '2015-03-01'.to_date,
             characters: 600)
      create(:revision,
             user:,
             article: draft,
             date: '2015-03-01'.to_date,
             characters: 700)
      # create the CoursesUsers record
      courses_user
    end

    it 'updates data for course-user relationships' do
      # Update caches for all CoursesUsers
      described_class.update_all_caches(described_class.all)

      # Fetch the created CoursesUsers entry
      course_user = described_class.all.first

      # Check to see if the expected data got cached
      expect(course_user.revision_count).to eq(4)
      expect(course_user.assigned_article_title).to eq('Selfie')
      expect(course_user.character_sum_ms).to eq(9000)
      expect(course_user.character_sum_us).to eq(600)
      expect(course_user.character_sum_draft).to eq(700)
      expect(course_user.references_count).to eq(5)
      expect(course_user.real_name).to eq('John Smith')
    end

    it 'updates cache only from tracked revisions' do
      # Untrack article in mainspace
      ArticlesCourses.find_by(article:, course:).update(tracked: false)
      described_class.update_all_caches(described_class.all)

      # Fetch the created CoursesUsers entry
      course_user = described_class.all.first

      # Check the stats don't consider the revision for the untracked article in mainspace
      # Only consider three revisions - for talk_page, draft and sandbox
      expect(course_user.revision_count).to eq(3)
      # characters in tracked namespaces are now 0
      expect(course_user.character_sum_ms).to eq(0)
      expect(course_user.character_sum_us).to eq(600)
      expect(course_user.character_sum_draft).to eq(700)
      # references count is 0 because there are no revisions in tracked namespaces now
      expect(course_user.references_count).to eq(0)
    end
  end

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
