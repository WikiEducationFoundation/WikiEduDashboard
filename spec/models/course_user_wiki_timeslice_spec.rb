# frozen_string_literal: true
# == Schema Information
#
# Table name: course_user_wiki_timeslices
#
#  id                  :bigint           not null, primary key
#  course_user_id      :integer          not null
#  wiki_id             :integer          not null
#  start               :datetime
#  end                 :datetime
#  last_mw_rev_id      :integer
#  total_uploads       :integer          default(0)
#  character_sum_ms    :integer          default(0)
#  character_sum_us    :integer          default(0)
#  character_sum_draft :integer          default(0)
#  references_count    :integer          default(0)
#  revision_count      :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'rails_helper'

describe CourseUserWikiTimeslice, type: :model do
  # before { stub_wiki_validation }

  describe '#update_cache_from_revisions' do
    let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
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
             user:)
    end
    let(:course_user_wiki_timeslice) do
      create(:course_user_wiki_timeslice,
             course_user_id: courses_user.id,
             wiki_id: enwiki.id,
             total_uploads: 0,
             character_sum_ms: 3,
             character_sum_us: 4,
             character_sum_draft: 2,
             references_count: 13,
             revision_count: 23)
    end
    let(:revision0) do
      create(:revision, article:,
             characters: 123,
             features: { 'num_ref' => 8 },
             features_previous: { 'num_ref' => 1 },
             user_id: course.id)
    end
    let(:revision1) do
      create(:revision, article: talk_page,
             characters: 200,
             features: { 'num_ref' => 12 },
             features_previous: { 'num_ref' => 10 },
             user_id: course.id)
    end
    let(:revision2) do
      create(:revision, article: sandbox,
             characters: -65,
             features: { 'num_ref' => 1 },
             features_previous: { 'num_ref' => 2 },
             user_id: course.id)
    end
    let(:revision3) do
      create(:revision, article: draft,
             characters: 225,
             features: { 'num_ref' => 3 },
             features_previous: { 'num_ref' => 3 },
             user_id: course.id)
    end
    let(:revision4) do
      create(:revision, article:,
              characters: 34,
              deleted: true, # deleted revision
              features: { 'num_ref' => 2 },
              features_previous: { 'num_ref' => 0 },
              user_id: course.id)
    end
    let(:revision5) do
      create(:revision, article_id: -1, # revision for a non-existing article
              characters: 34,
              deleted: false,
              features: { 'num_ref' => 2 },
              features_previous: { 'num_ref' => 0 },
              user_id: course.id)
    end
    let(:revisions) { [revision0, revision1, revision2, revision3, revision4, revision5] }
    let(:subject) { course_user_wiki_timeslice.update_cache_from_revisions revisions }

    before do
      # Make an article-course.
      create(:articles_course,
             article:,
             course:)

      # Create a common upload for the user
      create(:commons_upload, user:, uploaded_at: '2015-02-01'.to_date)

      # create the CoursesUsers record
      courses_user
    end

    it 'updates caches respecting the namespaces' do
      # Update caches
      subject

      # Fetch the created CourseUserWikiTimeslice entry
      course_user_wiki_timeslice = described_class.all.first

      expect(course_user_wiki_timeslice.total_uploads).to eq(1)
      # Don't consider deleted revisions or revisions for articles that don't exist
      expect(course_user_wiki_timeslice.revision_count).to eq(27)
      # Only consider revision0 (mainspace)
      expect(course_user_wiki_timeslice.character_sum_ms).to eq(126)
      # Only consider revision2 (sandbox)
      expect(course_user_wiki_timeslice.character_sum_us).to eq(4)
      # Only consider revision3 (draft)
      expect(course_user_wiki_timeslice.character_sum_draft).to eq(227)
      # Only consider revision0 (mainspace)
      expect(course_user_wiki_timeslice.references_count).to eq(20)
    end

    it 'only updates cache from tracked revisions' do
      ArticlesCourses.first.update(tracked: false)
      subject

      # Fetch the created CourseUserWikiTimeslice entry
      course_user_wiki_timeslice = described_class.all.first

      # Only considers revisions for sandbox, talk_page and draft articles
      expect(course_user_wiki_timeslice.revision_count).to eq(26)
      # No revision is taken into account for character_sum_ms
      expect(course_user_wiki_timeslice.character_sum_ms).to eq(3)
      # Negative characters for sanbox revision don't change the sum
      expect(course_user_wiki_timeslice.character_sum_us).to eq(4)
      # Characters from raft revision is considered
      expect(course_user_wiki_timeslice.character_sum_draft).to eq(227)
      # No revision is taken into account for references_count
      expect(course_user_wiki_timeslice.references_count).to eq(13)
    end
  end
end
