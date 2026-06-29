# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/monthly_report"

describe MonthlyReport do
  before do
    travel_to Date.new(2025, 5, 6)

    @first_course = nil
    @first_article = nil
    6.times do |i|
      course = create(:course, start: 2.years.ago, end: Time.zone.today, slug: "foo/#{i}")
      user = create(:user, username: "user_monthly_#{i}")
      create(:courses_user, user:, course:, role: 0)
      article = create(:article, title: "Article_#{i}", namespace: Article::Namespaces::MAINSPACE)
      @first_course ||= course
      @first_article ||= article
      create(:article_course_timeslice, course:, article:, revision_count:,
             start: 1.month.ago, end: 1.month.ago + 1.day)
      create(:article_course_timeslice, course:, article:, revision_count:,
             start: 1.month.ago + 1.day, end: 1.month.ago + 2.days)
      create(:article_course_timeslice, course:, article:, revision_count:,
             start: 2.months.ago, end: 2.months.ago + 1.day)
      create(:commons_upload, user:, uploaded_at: 1.month.ago, usage_count: 1)

      # Create old data for 4 of 6 courses
      next if [1, 4].include?(i)
      second_user = create(:user, username: "second_user_monthly_#{i}")
      create(:courses_user, user: second_user, course:, role: 0)
      old_article = create(:article, title: "Article_old_#{i}")
      create(:article_course_timeslice, course:, article: old_article, revision_count:,
             start: 13.months.ago, end: 13.months.ago + 1.day)
      create(:commons_upload, user: second_user, uploaded_at: 13.months.ago, usage_count: 1)
      create(:commons_upload, user: second_user, uploaded_at: 13.months.ago, usage_count: 1)
    end
  end

  after do
    travel_back
  end

  describe '.run' do
    context 'when timeslices have revisions' do
      let(:revision_count) { 15 }
      let(:subject) { described_class.run }

      it 'counts articles and uploads' do
        expect(subject[:'2025-4']).to(eq({ articles_edited: 6, uploads: 6 }))
        expect(subject[:'2024-4']).to(eq({ articles_edited: 4, uploads: 8 }))
      end

      it 'counts only articles in namespace' do
        @first_article.update(namespace: Article::Namespaces::WIKIJUNIOR)
        expect(subject[:'2025-4']).to(eq({ articles_edited: 5, uploads: 6 }))
        expect(subject[:'2024-4']).to(eq({ articles_edited: 4, uploads: 8 }))
      end

      it 'counts only tracked articles' do
        ArticleCourseTimeslice.where(course: @first_course, article: @first_article)
                              .update_all(tracked: false) # rubocop:disable Rails/SkipsModelValidations
        expect(subject[:'2025-4']).to(eq({ articles_edited: 5, uploads: 6 }))
        expect(subject[:'2024-4']).to(eq({ articles_edited: 4, uploads: 8 }))
      end
    end

    context 'when timeslices are empty' do
      let(:revision_count) { 0 }
      let(:subject) { described_class.run }

      it 'only counts uploads' do
        expect(subject[:'2025-4']).to(eq({ articles_edited: 0, uploads: 6 }))
        expect(subject[:'2024-4']).to(eq({ articles_edited: 0, uploads: 8 }))
      end
    end
  end
end
