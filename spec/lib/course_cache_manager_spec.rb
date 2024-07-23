# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_cache_manager"

describe CourseCacheManager do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:article) { create(:article, id: 1, namespace: 0) }
  let(:course) do
    create(:course, start: Time.zone.today - 1.month, end: Time.zone.today + 1.month)
  end

  before do
    create(:user, id: 1, username: 'Ragesoss')
    create(:user, id: 2, username: 'Gatoespecie')

    create(:articles_course, id: 1, article:, course:, view_count: 4, new_article: true)
    create(:articles_course, id: 2, article:, course:, view_count: 3)

    create(:courses_user, id: 1, course:, user_id: 1)
    create(:courses_user, id: 2, course:, user_id: 2)
    create(:courses_user, id: 3, course:, user_id: 2, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

    create(:commons_upload, user_id: 1, uploaded_at: 10.days.ago, usage_count: 3)
    create(:commons_upload, user_id: 2, uploaded_at: 10.days.ago, usage_count: 4)

    create(:course_wiki_timeslice,
           course:,
           wiki:,
           start: 10.days.ago,
           end: 9.days.ago,
           character_sum: 9000,
           references_count: 4,
           revision_count: 5,
           upload_count: 400,
           uploads_in_use_count: 200,
           upload_usages_count: 200)
    create(:course_wiki_timeslice,
           course:,
           wiki:,
           start: 9.days.ago,
           end: 8.days.ago,
           character_sum: 10,
           references_count: 3,
           revision_count: 1,
           upload_count: 30,
           uploads_in_use_count: 200,
           upload_usages_count: 200)
    create(:course_wiki_timeslice,
           course:,
           wiki:,
           start: 8.days.ago,
           end: 7.days.ago,
           character_sum: 100,
           references_count: 4,
           revision_count: 4,
           upload_count: 330,
           uploads_in_use_count: 100,
           upload_usages_count: 200)
  end

  describe '#update_cache_from_timeslices' do
    it 'updates caches based on timeslices records' do
      described_class.new(course).update_cache_from_timeslices course.course_wiki_timeslices
      expect(course.character_sum).to eq(9110)
      expect(course.references_count).to eq(11)
      expect(course.revision_count).to eq(10)
    end

    it 'updates caches based on existing articles courses records' do
      described_class.new(course).update_cache_from_timeslices []
      expect(course.view_sum).to eq(7)
      expect(course.article_count).to eq(2)
      expect(course.new_article_count).to eq(1)
    end

    it 'updates user_count based on existing course students' do
      described_class.new(course).update_cache_from_timeslices []
      expect(course.user_count).to eq(2)
    end

    it 'updates trained_count based on existing course students' do
      described_class.new(course).update_cache_from_timeslices []
      expect(course.trained_count).to eq(2)
    end

    it 'updates uploads based on existing article courses records' do
      described_class.new(course).update_cache_from_timeslices []
      # TODO: modify to be calculated from course wiki timeslices values
      expect(course.upload_count).to eq(2)
      expect(course.uploads_in_use_count).to eq(2)
      expect(course.upload_usages_count).to eq(7)
    end
  end
end
