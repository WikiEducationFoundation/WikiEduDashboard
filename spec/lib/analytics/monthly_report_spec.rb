# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/monthly_report"

describe MonthlyReport do
  let(:course_ids) { [1, 2, 3, 10001, 10002, 10003] }

  before do
    travel_to Date.new(2025, 5, 6)

    course_ids.each do |i|
      # Course
      id = i
      id2 = id + 100
      create(:course, id:, start: 2.years.ago, end: Time.zone.today, slug: "foo/#{id}")
      create(:user, id:, username: "user#{id}")
      create(:courses_user, id:, user_id: id, course_id: id, role: 0)
      # Create two articles
      create(:article, id:, title: "Article_#{id}", namespace: Article::Namespaces::MAINSPACE)
      # Create timeslices
      create(:article_course_timeslice, course_id: id, article_id: id,
      start: 1.month.ago, end: 1.month.ago + 1.day)
      create(:article_course_timeslice, course_id: id, article_id: id,
      start: 1.month.ago + 1.day, end: 1.month.ago + 2.days)
      create(:article_course_timeslice, course_id: id, article_id: id,
      start: 2.months.ago, end: 2.months.ago + 1.day)
      # Create uploads
      create(:commons_upload, id:, user_id: id, uploaded_at: 1.month.ago, usage_count: 1)

      # only create old revision for some courses
      next unless id2.odd?
      create(:user, id: id2, username: "second_user#{id}")
      create(:courses_user, id: id2, user_id: id2, course_id: id, role: 0)
      # Create article
      create(:article, id: id2, title: "Article_#{id2}")
      # Create timeslice
      create(:article_course_timeslice, course_id: id, article_id: id2,
      start: 13.months.ago, end: 13.months.ago + 1.day)
      # Create uploads
      create(:commons_upload, user_id: id2, uploaded_at: 13.months.ago, usage_count: 1)
      create(:commons_upload, user_id: id2, uploaded_at: 13.months.ago, usage_count: 1)
    end
  end

  after do
    travel_back
  end

  describe '.run' do
    let(:subject) { described_class.run }

    it 'counts articles and uploads' do
      expect(subject[:'2025-4']).to(eq({ articles_edited: 6, uploads: 6 }))
      expect(subject[:'2024-4']).to(eq({ articles_edited: 4, uploads: 8 }))
    end
  end
end
