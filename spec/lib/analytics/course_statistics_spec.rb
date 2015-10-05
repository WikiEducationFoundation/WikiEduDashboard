require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_statistics"

describe CourseStatistics do
  let(:course_ids) { [1, 2, 3, 10001, 10002, 10003] }
  before do
    course_ids.each do |i|
      # Course
      id = i
      id2 = id + 100
      create(:course, id: id, start: 1.year.ago, end: Time.zone.today)
      # First user in course working within course dates
      create(:user, id: id)
      create(:courses_user, id: id, user_id: id, course_id: id, role: 0)
      create(:revision, date: 1.day.ago, article_id: id, user_id: id)
      create(:article, id: id, title: "Article_#{id}")
      create(:commons_upload, id: id, user_id: id, uploaded_at: 1.day.ago, usage_count: 1)

      # Second user in course working outside course dates
      create(:user, id: id2)
      create(:courses_user, id: id2, user_id: id2, course_id: id2, role: 0)
      create(:revision, date: 2.years.ago, article_id: id2, user_id: id2)
      create(:article, id: id2, title: "Article_#{id2}")
      create(:commons_upload, id: id2, user_id: id2, uploaded_at: 2.years.ago, usage_count: 1)
    end
  end

  describe '#report_statistics' do
    it 'should work for empty cohorts' do
      output = CourseStatistics.new([]).report_statistics
      expect(output[:course_count]).to eq(0)
      expect(output[:students_excluding_instructors]).to eq(0)
    end

    let(:subject) { CourseStatistics.new(course_ids).report_statistics }

    it 'should count articles, revisions and uploads from during courses' do
      expect(subject[:course_count]).to eq(course_ids.count)
      expect(subject[:students_excluding_instructors]).to eq(course_ids.count)
      expect(subject[:file_uploads]).to eq(course_ids.count)
      expect(subject[:revisions]).to eq(course_ids.count)
      expect(subject[:articles_edited]).to eq(course_ids.count)
      expect(subject[:file_uploads]).to eq(course_ids.count)
      expect(subject[:files_in_use]).to eq(course_ids.count)
      expect(subject[:global_usages]).to eq(course_ids.count)
    end
  end

  describe '#articles_edited' do
    it 'should work for empty cohorts' do
      output = CourseStatistics.new([]).articles_edited
      expect(output).to be_empty
    end

    it 'should return articles edited during courses' do
      output = CourseStatistics.new(course_ids).articles_edited
      expect(output).to include(Article.find(1))
      expect(output).not_to include(Article.find(101))
    end
  end
end
