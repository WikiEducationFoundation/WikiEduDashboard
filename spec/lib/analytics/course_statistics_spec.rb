# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_statistics"

describe CourseStatistics do
  let(:course_ids) { [1, 2, 3, 10001, 10002, 10003] }
  let(:wiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }

  before do
    course_ids.each do |i|
      # Course
      id = i
      id2 = id + 100
      create(:course, id:, start: 1.year.ago, end: Time.zone.today, slug: "foo/#{id}")
      # First user in course working within course dates
      create(:user, id:, username: "user#{id}")
      create(:courses_user, id:, user_id: id, course_id: id, role: 0)
      create(:article, id:, title: "Article_#{id}", namespace: Article::Namespaces::MAINSPACE)
      create(:commons_upload, id:, user_id: id, uploaded_at: 1.day.ago, usage_count: 1)

      # The user also has common uploads before the course dates
      create(:commons_upload, id: id2, user_id: id, uploaded_at: 2.years.ago, usage_count: 1)

      # Create timeslices
      create(:course_wiki_timeslice, course_id: id, wiki:, revision_count: id,
      start: 1.month.ago, end: 1.month.ago + 1.day)
      create(:article_course_timeslice, course_id: id, article_id: id, revision_count: 1,
      new_article: id == 1, start: 1.month.ago, end: 1.month.ago + 1.day)
      create(:course_user_wiki_timeslice, course_id: id, user_id: id, wiki:, character_sum_ms: id,
      references_count: id, start: 1.month.ago, end: 1.month.ago + 1.day)

      # Update caches
      CoursesUsers.find_by(course_id: id, user_id: id).update_cache_from_timeslices
      Course.find(id).update_cache_from_timeslices
    end
  end

  describe '#report_statistics' do
    let(:subject) { described_class.new(course_ids).report_statistics }

    it 'works for empty campaigns' do
      output = described_class.new([]).report_statistics
      expect(output[:course_count]).to eq(0)
      expect(output[:students_excluding_instructors]).to eq(0)
    end

    it 'counts courses, students, revisions and articles' do
      expect(subject[:course_count]).to eq(course_ids.count)
      expect(subject[:students_excluding_instructors]).to eq(course_ids.count)
      expect(subject[:revisions]).to eq(30012)
      expect(subject[:articles_edited]).to eq(course_ids.count)
      expect(subject[:articles_created]).to eq(1)
      expect(subject[:articles_deleted]).to eq(0)
      expect(subject[:characters_added]).to eq(30012)
      expect(subject[:words_added]).to eq(5799)
      expect(subject[:references_added]).to eq(30012)
    end

    it 'counts new articles that got deleted' do
      Article.find(1).update(deleted: true)
      expect(subject[:articles_created]).to eq(0)
      expect(subject[:articles_deleted]).to eq(1)
    end

    it 'counts uploads from during courses' do
      expect(subject[:file_uploads]).to eq(course_ids.count)
      expect(subject[:file_uploads]).to eq(course_ids.count)
      expect(subject[:files_in_use]).to eq(course_ids.count)
      expect(subject[:global_usages]).to eq(course_ids.count)
    end

    it 'counts only tracked articles' do
      ArticleCourseTimeslice.find_by(course_id: 1, article_id: 1).update(tracked: false)
      ArticleCourseTimeslice.find_by(course_id: 2, article_id: 2).update(revision_count: 0)
      expect(subject[:articles_edited]).to eq(course_ids.count - 2)
    end

    it 'counts only articles in namespace' do
      Article.find(1).update(namespace: Article::Namespaces::WIKIJUNIOR)
      expect(subject[:articles_edited]).to eq(course_ids.count - 1)
    end
  end

  describe '#articles_edited' do
    it 'works for empty campaigns' do
      output = described_class.new([]).articles_edited
      expect(output).to be_empty
    end

    it 'returns articles in namespace' do
      Article.find(2).update(namespace: Article::Namespaces::WIKIJUNIOR)
      output = described_class.new(course_ids).articles_edited
      expect(output).to include(Article.find(1))
      expect(output).not_to include(Article.find(2))
    end
  end
end
