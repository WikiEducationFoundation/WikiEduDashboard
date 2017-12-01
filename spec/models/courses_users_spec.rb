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
#

require 'rails_helper'

describe CoursesUsers, type: :model do
  before { stub_wiki_validation }

  describe '.update_all_caches' do
    it 'updates data for course-user relationships' do
      # Add a user, a course, an article, and a revision.
      create(:user,
             id: 1,
             username: 'Ragesoss')

      create(:course,
             id: 1,
             start: '2015-01-01'.to_date,
             end: '2015-07-01'.to_date,
             title: 'Underwater basket-weaving')

      create(:article,
             id: 1,
             title: 'Selfie',
             namespace: 0)

      create(:revision,
             id: 1,
             user_id: 1,
             article_id: 1,
             date: '2015-03-01'.to_date,
             characters: 9000)

      # Assign the article to the user.
      create(:assignment,
             course_id: 1,
             user_id: 1,
             article_id: 1,
             article_title: 'Selfie')

      # Make a course-user and save it.
      create(:courses_user,
             id: 1,
             course_id: 1,
             user_id: 1,
             assigned_article_title: 'Selfie',
             real_name: 'John Smith')

      # Make an article-course.
      create(:articles_course,
             id: 1,
             article_id: 1,
             course_id: 1)

      # Update caches for all CoursesUsers
      CoursesUsers.update_all_caches(CoursesUsers.find(1))

      # Fetch the created CoursesUsers entry
      course_user = CoursesUsers.all.first

      # Check to see if the expected data got cached
      expect(course_user.revision_count).to eq(1)
      expect(course_user.assigned_article_title).to eq('Selfie')
      expect(course_user.character_sum_ms).to eq(9000)
      expect(course_user.character_sum_us).to eq(0)
      expect(course_user.real_name).to eq('John Smith')
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

  describe '.update_all_caches_concurrently' do
    it 'calls .update_all_caches multiple times' do
      concurrency = 6
      expect(CoursesUsers).to receive(:update_all_caches)
        .exactly(concurrency).times
      CoursesUsers.update_all_caches_concurrently(concurrency)
    end
  end
end
