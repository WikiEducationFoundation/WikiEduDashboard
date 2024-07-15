# frozen_string_literal: true

# == Schema Information
#
# Table name: course_wiki_timeslices
#
#  id                   :bigint           not null, primary key
#  course_wiki_id       :integer          not null
#  start                :datetime
#  end                  :datetime
#  last_mw_rev_id       :integer
#  character_sum        :integer          default(0)
#  references_count     :integer          default(0)
#  revision_count       :integer          default(0)
#  upload_count         :integer          default(0)
#  uploads_in_use_count :integer          default(0)
#  upload_usages_count  :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require 'rails_helper'

describe CourseWikiTimeslice, type: :model do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:array_revisions) { [] }
  let(:article) { create(:article, id: 1, namespace: 0) }
  let(:course) do
    create(:course, start: Time.zone.today - 1.month, end: Time.zone.today + 1.month)
  end

  before do
    create(:user, id: 1, username: 'Ragesoss')
    create(:user, id: 2, username: 'Gatoespecie')

    create(:articles_course, id: 1, article_id: 1, course:)

    create(:courses_user, id: 1, course:, user_id: 1)
    create(:courses_user, id: 2, course:, user_id: 2)
    create(:courses_user, id: 3, course:, user_id: 2,
role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

    create(:commons_upload, user_id: 1, uploaded_at: 10.days.ago, usage_count: 3)
    create(:commons_upload, user_id: 2, uploaded_at: 10.days.ago, usage_count: 4)

    create(:course_user_wiki_timeslice,
           course:,
           user_id: 1,
           wiki:,
           start: 10.days.ago,
           end: 9.days.ago,
           character_sum_ms: 9000,
           character_sum_us: 500,
           character_sum_draft: 400,
           total_uploads: 200,
           references_count: 4,
           revision_count: 5)
    create(:course_user_wiki_timeslice,
           course:,
           user_id: 2,
           wiki:,
           start: 10.days.ago,
           end: 9.days.ago,
           character_sum_ms: 10,
           character_sum_us: 20,
           character_sum_draft: 30,
           total_uploads: 200,
           references_count: 3,
           revision_count: 1)
    # Course user wiki timeslice for non-student
    create(:course_user_wiki_timeslice,
           course:,
           user_id: 3,
           wiki:,
           start: 10.days.ago,
           end: 9.days.ago,
           character_sum_ms: 100,
           character_sum_us: 200,
           character_sum_draft: 330,
           total_uploads: 100,
           references_count: 4,
           revision_count: 4)

    array_revisions << build(:revision, article:, user_id: 1)
    array_revisions << build(:revision, article:, user_id: 1)
    array_revisions << build(:revision, article:, user_id: 2)
    array_revisions << build(:revision, article:, deleted: true, user_id: 1)
  end

  describe '#update_cache_from_revisions' do
    it 'caches revision data for students' do
      # Get the CoursesWikis record automatically created
      course_wiki = CoursesWikis.find_by(course:, wiki:)
      # Make a course wiki timeslice
      create(:course_wiki_timeslice,
             id: 1,
             course_wiki_id: course_wiki.id,
             character_sum: 1,
             references_count: 1,
             revision_count: 1,
             upload_count: 100,
             uploads_in_use_count: 100,
             upload_usages_count: 100)

      course_wiki_timeslice = described_class.find(1)
      course_wiki_timeslice.update_cache_from_revisions array_revisions

      expect(course_wiki_timeslice.character_sum).to eq(9011)
      expect(course_wiki_timeslice.references_count).to eq(8)
      expect(course_wiki_timeslice.revision_count).to eq(4)
      expect(course_wiki_timeslice.upload_count).to eq(2)
      expect(course_wiki_timeslice.uploads_in_use_count).to eq(2)
      expect(course_wiki_timeslice.upload_usages_count).to eq(7)
    end

    it 'revision count cache only considers tracked articles courses' do
      # Untrack articles courses record
      ArticlesCourses.find(1).update(tracked: 0)
      # Get the CoursesWikis record automatically created
      course_wiki = CoursesWikis.find_by(course:, wiki:)
      # Make a course wiki timeslice
      create(:course_wiki_timeslice,
             id: 1,
             course_wiki_id: course_wiki.id,
             character_sum: 1,
             references_count: 1,
             revision_count: 1,
             upload_count: 100,
             uploads_in_use_count: 100,
             upload_usages_count: 100)

      course_wiki_timeslice = described_class.find(1)
      course_wiki_timeslice.update_cache_from_revisions array_revisions

      expect(course_wiki_timeslice.character_sum).to eq(9011)
      expect(course_wiki_timeslice.references_count).to eq(8)
      # Don't add any new revision count
      expect(course_wiki_timeslice.revision_count).to eq(1)
      expect(course_wiki_timeslice.upload_count).to eq(2)
      expect(course_wiki_timeslice.uploads_in_use_count).to eq(2)
      expect(course_wiki_timeslice.upload_usages_count).to eq(7)
    end
  end
end
