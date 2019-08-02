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
    # Fetch the original data
    VCR.use_cassette 'course_upload_importer/Hbultra' do
      UpdateCourseStats.new(course)
    end

    # Check if the data is cached
    old_character_sum = course.character_sum
    expect(course.character_sum).to eq(old_character_sum)
    expect(CoursesUsers.first.character_sum_ms).to eq(old_character_sum)
    expect(course.articles_courses.tracked.sum(:character_sum)).to eq(old_character_sum)
    expect(course.revisions.count).to eq(course.tracked_revisions.count)

    # Exclude an article from being tracked
    untracked_id = Article.find_by(title: 'Afterload').id
    course.articles_courses.where(article_id: untracked_id).update(tracked: false)

    # Update the data to reflect the new data
    VCR.use_cassette 'course_upload_importer/Hbultra' do
      UpdateCourseStats.new(course)
    end

    # Check if the updated cached data is lesser than previous data due to excluded articles
    expect(course.character_sum).to be < old_character_sum
    expect(course.articles_courses.tracked.sum(:character_sum)).to be < old_character_sum
    expect(CoursesUsers.first.character_sum_ms).to be < old_character_sum
    expect(course.tracked_revisions.count).to be < course.revisions.count
  end
end
