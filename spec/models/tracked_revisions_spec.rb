# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/analytics/course_statistics.rb"

describe 'Course#tracked_revisions' do
  let(:course) { create(:course, start: '10-07-2019'.to_date, end: '10-08-2019'.to_date) }
  let(:different_wiki_course) do
    create(:course,
           title: 'Science',
           school: 'WinterSchool',
           term: 'Winter 2019',
           slug: 'WinterSchool/Science_(Winter_2019)',
           start: '10-07-2019'.to_date, end: '10-08-2019'.to_date,
           home_wiki_id: 3)
  end
  let(:user) { create(:user, username: 'Hbultra') }

  before do
    course.students << user
    different_wiki_course.students << user
  end

  it 'fetches the course stats for only tracked articles' do
    # Fetch the original data
    VCR.use_cassette 'cached/course_upload_importer/Hbultra' do
      UpdateCourseStats.new(course)
      UpdateCourseStats.new(different_wiki_course)
    end

    # Check if the data is cached
    old_character_sum = course.character_sum
    old_course = course.dup
    expect(course.revision_count).to eq(old_course.revision_count)
    expect(different_wiki_course.revision_count).to eq(0)
    expect(course.view_sum).to eq(old_course.view_sum)
    expect(course.references_count).to eq(old_course.references_count)
    expect(course.article_count).to eq(old_course.article_count)
    expect(course.new_article_count).to eq(old_course.new_article_count)
    expect(course.character_sum).to eq(old_character_sum)
    expect(CoursesUsers.first.character_sum_ms).to eq(old_character_sum)
    expect(course.articles_courses.tracked.sum(:character_sum)).to eq(old_character_sum)
    expect(course.revisions.count).to eq(course.tracked_revisions.count)

    # Exclude an article from being tracked
    untracked_id = Article.find_by(title: 'Afterload').id
    course.articles_courses.where(article_id: untracked_id).update(tracked: false)

    # Update the data to reflect the new data
    VCR.use_cassette 'cached/course_upload_importer/Hbultra' do
      UpdateCourseStats.new(course)
    end
    # Check if the updated cached data is lesser than previous data due to excluded articles
    expect(course.revision_count).to be < old_course.revision_count
    expect(course.view_sum).to eq(0).or be < old_course.view_sum
    expect(course.references_count).to eq(0).or be < old_course.references_count
    expect(course.article_count).to be < old_course.article_count
    expect(course.new_article_count).to eq(0).or be < old_course.new_article_count
    expect(course.character_sum).to be < old_character_sum
    expect(course.articles_courses.tracked.sum(:character_sum)).to be < old_character_sum
    expect(CoursesUsers.first.character_sum_ms).to be < old_character_sum
    expect(course.tracked_revisions.count).to be < course.revisions.count
  end
end
