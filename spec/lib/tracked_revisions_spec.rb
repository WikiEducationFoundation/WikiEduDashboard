# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/analytics/course_statistics.rb"

describe 'TrackedRevisions' do
  let(:course) { create(:course, start: '30-05-2019'.to_date, end: '31-07-2019'.to_date) }
  let(:user) { create(:user, username: 'Textorus') }

  before do
    course.students << user
  end

  it 'fetches the course stats for only tracked articles' do
    VCR.use_cassette 'course_upload_importer/Textorus' do
      UpdateCourseStats.new(course)
    end
    subject = CourseStatistics.new([course.id]).report_statistics
    expect(subject[:articles_edited]).to eq(151)
    expect(subject[:characters_added]).to eq(7680)
    course.articles_courses.take(10).each do |article_course|
      article_course.update(tracked: false)
    end
    VCR.use_cassette 'course_upload_importer/Textorus' do
      UpdateCourseStats.new(course)
    end
    subject = CourseStatistics.new([course.id]).report_statistics
    expect(subject[:articles_edited]).to be < 151
    expect(subject[:characters_added]).to be < 7680
  end
end
