# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/analytics/course_statistics.rb"

describe 'Course#tracked_revisions' do
  let(:course) { create(:course, start: '10-07-2019'.to_date, end: '10-08-2019'.to_date) }
  let(:user) { create(:user, username: 'Hbultra') }

  before do
    course.students << user
  end

  it 'fetches the course stats for only tracked articles' do
    VCR.use_cassette 'course_upload_importer/Hbultra' do
      UpdateCourseStats.new(course)
    end
    expect(course.revisions.count).to eq(course.tracked_revisions.count)
    untracked_id = Article.find_by(title: 'Afterload').id
    course.articles_courses.where(article_id: untracked_id).update(tracked: false)
    VCR.use_cassette 'course_upload_importer/Hbultra' do
      UpdateCourseStats.new(course)
    end
    expect(course.tracked_revisions.count).to be < course.revisions.count
  end
end
