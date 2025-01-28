# frozen_string_literal: true
# == Schema Information
#
# Table name: course_user_wiki_timeslices
#
#  id                  :bigint           not null, primary key
#  course_id           :integer          not null
#  user_id             :integer          not null
#  wiki_id             :integer          not null
#  start               :datetime
#  end                 :datetime
#  character_sum_ms    :integer          default(0)
#  character_sum_us    :integer          default(0)
#  character_sum_draft :integer          default(0)
#  references_count    :integer          default(0)
#  revision_count      :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe CourseUserWikiTimeslice, type: :model do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }
  let(:user) { create(:user, username: 'User') }
  let(:start) { '2015-01-01'.to_date }
  let(:course) { create(:course, start:, end: '2015-07-01'.to_date) }
  let(:article) { create(:article, title: 'Selfie') }
  let(:talk_page) { create(:article, title: 'Selfie', namespace: Article::Namespaces::TALK) }
  let(:sandbox) { create(:article, title: 'User/Selfie', namespace: Article::Namespaces::USER) }
  let(:draft) { create(:article, title: 'Selfie', namespace: Article::Namespaces::DRAFT) }
  let(:courses_user) do
    create(:courses_user,
           course:,
           user:)
  end
  let(:course_user_wiki_timeslice) do
    create(:course_user_wiki_timeslice,
           course:,
           user:,
           wiki_id: wiki.id,
           character_sum_ms: 3,
           character_sum_us: 4,
           character_sum_draft: 2,
           references_count: 13,
           revision_count: 23)
  end
  let(:revision0) do
    build(:revision, article:, date: start,
           characters: 123,
           features: { 'num_ref' => 8 },
           features_previous: { 'num_ref' => 1 },
           user_id: user.id,
           views: true)
  end
  let(:revision1) do
    build(:revision, article: talk_page, date: start,
           characters: 200,
           features: { 'num_ref' => 12 },
           features_previous: { 'num_ref' => 10 },
           user_id: user.id,
           views: true)
  end
  let(:revision2) do
    build(:revision, article: sandbox, date: start,
           characters: -65,
           features: { 'num_ref' => 1 },
           features_previous: { 'num_ref' => 2 },
           user_id: user.id,
           views: true)
  end
  let(:revision3) do
    build(:revision, article: draft, date: start,
           characters: 225,
           features: { 'num_ref' => 3 },
           features_previous: { 'num_ref' => 3 },
           user_id: user.id,
           views: true)
  end
  let(:revision4) do
    build(:revision, article:, date: start,
            characters: 34,
            deleted: true, # deleted revision
            features: { 'num_ref' => 2 },
            features_previous: { 'num_ref' => 0 },
            user_id: user.id,
            views: true)
  end
  let(:revision5) do
    build(:revision, article_id: -1, # revision for a non-existing article
            date: start,
            characters: 34,
            deleted: false,
            features: { 'num_ref' => 2 },
            features_previous: { 'num_ref' => 0 },
            user_id: user.id,
            views: true)
  end
  let(:revision6) do
    build(:revision, article: draft, date: start,
           characters: 220,
           features: { 'num_ref' => 1 },
           features_previous: { 'num_ref' => 0 },
           user_id: user.id,
           system: true, # revision made by the system
           views: true)
  end
  let(:revisions) { [revision0, revision1, revision2, revision3, revision4, revision5, revision6] }
  let(:subject) { course_user_wiki_timeslice.update_cache_from_revisions revisions }

  describe '.update_course_user_wiki_timeslices' do
    before do
      TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records(course.wikis)
      revisions << build(:revision, article:, user_id: user.id, date: start + 26.hours, views: true)
      revisions << build(:revision, article:, user_id: user.id, date: start + 50.hours, views: true)
      revisions << build(:revision, article:, user_id: user.id, date: start + 51.hours, views: true)
    end

    it 'creates the right article timeslices based on the revisions' do
      expect(course.course_user_wiki_timeslices.count).to eq(0)

      start_period = start.strftime('%Y%m%d%H%M%S')
      end_period = (start + 55.hours).strftime('%Y%m%d%H%M%S')
      revision_data = { start: start_period, end: end_period, revisions: }
      described_class.update_course_user_wiki_timeslices(course, user.id, wiki, revision_data)

      course_user_wiki_timeslice_0 = described_class.find_by(course:, wiki:, user:, start:)
      course_user_wiki_timeslice_1 = described_class.find_by(course:, wiki:, user:,
                                                             start: start + 1.day)
      course_user_wiki_timeslice_2 = described_class.find_by(course:, wiki:, user:,
                                                             start: start + 2.days)

      expect(course_user_wiki_timeslice_0.revision_count).to eq(4)
      expect(course_user_wiki_timeslice_1.revision_count).to eq(1)
      expect(course_user_wiki_timeslice_2.revision_count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(3)
    end

    it 'updates the right article timeslices based on the revisions' do
      # Timeslices are already created
      create(:course_user_wiki_timeslice, course:, wiki:, user:, start:, end: start + 1.day)
      create(:course_user_wiki_timeslice, course:, wiki:, user:, start: start + 1.day,
             end: start + 2.days)
      create(:course_user_wiki_timeslice, course:, wiki:, user:, start: start + 2.days,
            end: start + 3.days)

      course_user_wiki_timeslice_0 = described_class.find_by(course:, wiki:, user:, start:)
      course_user_wiki_timeslice_1 = described_class.find_by(course:, wiki:, user:,
                                                             start: start + 1.day)
      course_user_wiki_timeslice_2 = described_class.find_by(course:, wiki:, user:,
                                                             start: start + 2.days)

      expect(course_user_wiki_timeslice_0.revision_count).to eq(0)
      expect(course_user_wiki_timeslice_1.revision_count).to eq(0)
      expect(course_user_wiki_timeslice_2.revision_count).to eq(0)

      start_period = start.strftime('%Y%m%d%H%M%S')
      end_period = (start + 55.hours).strftime('%Y%m%d%H%M%S')
      revision_data = { start: start_period, end: end_period, revisions: }
      described_class.update_course_user_wiki_timeslices(course, user.id, wiki, revision_data)

      course_user_wiki_timeslice_0 = described_class.find_by(course:, wiki:, user:, start:)
      course_user_wiki_timeslice_1 = described_class.find_by(course:, wiki:, user:,
                                                             start: start + 1.day)
      course_user_wiki_timeslice_2 = described_class.find_by(course:, wiki:, user:,
                                                             start: start + 2.days)

      expect(course_user_wiki_timeslice_0.revision_count).to eq(4)
      expect(course_user_wiki_timeslice_1.revision_count).to eq(1)
      expect(course_user_wiki_timeslice_2.revision_count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(3)
    end
  end

  describe '#update_cache_from_revisions' do
    before do
      # Make an article-course.
      create(:articles_course,
             article:,
             course:)

      # create the CoursesUsers record
      courses_user
    end

    it 'updates caches respecting the namespaces' do
      # Update caches
      subject

      # Fetch the created CourseUserWikiTimeslice entry
      course_user_wiki_timeslice = described_class.all.first

      # Don't consider deleted revisions, automatic revisions, or revisions for
      # articles that don't exist
      expect(course_user_wiki_timeslice.revision_count).to eq(4)
      # Only consider revision0 (mainspace)
      expect(course_user_wiki_timeslice.character_sum_ms).to eq(123)
      # Only consider revision2 (sandbox)
      expect(course_user_wiki_timeslice.character_sum_us).to eq(0)
      # Only consider revision3 (draft)
      expect(course_user_wiki_timeslice.character_sum_draft).to eq(225)
      # Only consider revision0 (mainspace)
      expect(course_user_wiki_timeslice.references_count).to eq(7)
    end

    it 'only updates cache from tracked revisions' do
      ArticlesCourses.first.update(tracked: false)
      subject

      # Fetch the created CourseUserWikiTimeslice entry
      course_user_wiki_timeslice = described_class.all.first

      # Only considers revisions for sandbox, talk_page and draft articles
      expect(course_user_wiki_timeslice.revision_count).to eq(3)
      # No revision is taken into account for character_sum_ms
      expect(course_user_wiki_timeslice.character_sum_ms).to eq(0)
      # Negative characters for sanbox revision don't change the sum
      expect(course_user_wiki_timeslice.character_sum_us).to eq(0)
      # Characters from draft revision is considered
      expect(course_user_wiki_timeslice.character_sum_draft).to eq(225)
      # No revision is taken into account for references_count
      expect(course_user_wiki_timeslice.references_count).to eq(0)
    end
  end
end
